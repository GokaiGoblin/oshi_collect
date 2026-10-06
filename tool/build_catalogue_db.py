"""Rebuild assets/db/holo_catalogue.db from the two card CSVs.

Run from the project root:   python3 tool/build_catalogue_db.py

What it does
  * Booster cards come from assets/holo_tcg_cards_sorted.csv (card_id kept).
  * Promo cards come from assets/holo_tcg_promos.csv. Rows with a blank
    card_id get a new id from the shared counter (never reused) and the id is
    written back into the promo CSV so it stays stable for future rebuilds.
  * Each promo event (the promo CSV's set_code column) becomes a set with
    set_type 'promo'. Promos with no event go into "Other Promos".
  * Prices are Japanese yen (price_jpy). A blank price stays NULL - never 0.
  * members is stored as "EN tags, JP names" so searches in either language
    match; JP names are looked up from the existing booster data.

After running it, bump _dbVersion in lib/db/catalogue_db.dart.
"""
import csv
import os
import re
import shutil
import sqlite3
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB = os.path.join(ROOT, 'assets', 'db', 'holo_catalogue.db')
BOOSTER_CSV = os.path.join(ROOT, 'assets', 'holo_tcg_cards_sorted.csv')
PROMO_CSV = os.path.join(ROOT, 'assets', 'holo_tcg_promos.csv')

# The highest card_id ever issued before this script assigned promo ids.
# IDs are never reused, so new ids always start above every id in either CSV.
MIN_NEXT_ID = 2259

# Member tags whose Japanese name can't be found on a card of their own.
EXTRA_JP = {
    'Ceres Fauna': 'セレス・ファウナ',
    'Harusaki Nodoka': '春先のどか',
}


def read_csv(path):
    with open(path, encoding='utf-8-sig', newline='') as f:
        rows = list(csv.DictReader(f))
    return rows, list(rows[0].keys())


def write_csv(path, rows, cols):
    with open(path, 'w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        w.writerows(rows)


def blank_to_none(v):
    v = (v or '').strip()
    return v or None


def price(v):
    v = (v or '').strip()
    return float(v) if v else None


def slug(text):
    return 'PR-' + re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')


def natural_key(text):
    # "vol.2" sorts before "vol.10"
    return [int(p) if p.isdigit() else p.lower() for p in re.split(r'(\d+)', text)]


def main():
    shutil.copy(DB, DB + '.bak')
    con = sqlite3.connect(DB)
    cur = con.cursor()

    boosters, _ = read_csv(BOOSTER_CSV)
    promos, promo_cols = read_csv(PROMO_CSV)

    # --- member tag -> JP name, learnt from the existing booster rows ---------
    tag_jp = dict(EXTRA_JP)
    db_members = dict(cur.execute('SELECT card_id, members FROM cards WHERE members IS NOT NULL'))
    for r in boosters:
        tags = [t.strip() for t in r['members'].split(',') if t.strip()]
        stored = [t.strip() for t in (db_members.get(int(r['card_id'])) or '').split(',') if t.strip()]
        jp = [t for t in stored if t not in tags]
        if len(tags) == len(jp):
            for t, j in zip(tags, jp):
                tag_jp.setdefault(t, j)
    for r in boosters:  # a member's own card: EN name -> JP name
        if r['name_en'] and r['name_jp'] and r['name_en'] not in tag_jp:
            tag_jp[r['name_en']] = r['name_jp']

    def members_field(tags_csv, card_id=None):
        tags = [t.strip() for t in (tags_csv or '').split(',') if t.strip()]
        if not tags:
            return None
        if card_id is not None and card_id in db_members:   # keep booster value as built before
            return db_members[card_id]
        jp = [tag_jp[t] for t in tags if t in tag_jp]
        return ', '.join(tags + jp)

    # --- assign ids to new promo rows ----------------------------------------
    used = {int(r['card_id']) for r in boosters + promos if r['card_id'].strip()}
    next_id = max(MIN_NEXT_ID, max(used) + 1)
    new_ids = 0
    for r in promos:
        if not r['card_id'].strip():
            r['card_id'] = str(next_id)
            next_id += 1
            new_ids += 1
    write_csv(PROMO_CSV, promos, promo_cols)

    # --- rebuild the cards table ---------------------------------------------
    cur.executescript('''
        DROP TABLE IF EXISTS cards_new;
        CREATE TABLE cards_new (
            card_id        INTEGER PRIMARY KEY AUTOINCREMENT,
            set_code       TEXT NOT NULL,
            name_jp        TEXT NOT NULL,
            name_en        TEXT,
            card_number    TEXT NOT NULL,
            rarity         TEXT,
            is_foil        INTEGER NOT NULL DEFAULT 0,
            is_signed      INTEGER NOT NULL DEFAULT 0,
            is_reprint     INTEGER NOT NULL DEFAULT 0,
            price_jpy      REAL,
            archetype      TEXT,
            artwork_rarity TEXT,
            members        TEXT,
            image_variant  TEXT,
            FOREIGN KEY(set_code) REFERENCES sets(set_code)
        );
    ''')
    old_artwork = dict(cur.execute('SELECT card_id, artwork_rarity FROM cards'))
    insert = ('INSERT INTO cards_new (card_id, set_code, name_jp, name_en, card_number, rarity, '
              'is_foil, is_signed, is_reprint, price_jpy, archetype, artwork_rarity, members, image_variant) '
              'VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)')
    for r in boosters:
        cid = int(r['card_id'])
        cur.execute(insert, (cid, r['set_code'], r['name_jp'], blank_to_none(r['name_en']),
                             r['card_number'], r['rarity'], int(r['is_foil'] or 0),
                             int(r['is_signed'] or 0), int(r['is_reprint'] or 0), price(r['price_jpy']),
                             blank_to_none(r['archetype']), old_artwork.get(cid),
                             members_field(r['members'], cid), None))

    # --- promo events become sets with set_type 'promo' ------------------------
    cur.execute("DELETE FROM sets WHERE set_type = 'promo'")
    events = {}
    for r in promos:
        events.setdefault(r['set_code'].strip() or 'Other Promos', []).append(r)
    for name in sorted(events, key=natural_key):
        cur.execute('INSERT INTO sets (set_code, name_en, name_jp, set_type, release_date, card_count, is_available) '
                    "VALUES (?, ?, NULL, 'promo', NULL, ?, 1)", (slug(name), name, len(events[name])))
    for name, rows in events.items():
        for r in rows:
            variant = r['image_variant'].strip()
            variant = f'{int(variant):02d}' if variant else None
            cur.execute(insert, (int(r['card_id']), slug(name), r['name_jp'] or r['name_en'] or r['card_number'],
                                 blank_to_none(r['name_en']), r['card_number'], r['rarity'] or 'P',
                                 int(r['is_foil'] or 0), int(r['is_signed'] or 0), int(r['is_reprint'] or 0),
                                 price(r['price_jpy']), blank_to_none(r['archetype']), None,
                                 members_field(r['members']), variant))

    cur.executescript('''
        DROP TABLE cards;
        ALTER TABLE cards_new RENAME TO cards;
        CREATE INDEX idx_cards_number ON cards(card_number);
        CREATE INDEX idx_cards_set    ON cards(set_code);
        CREATE INDEX idx_cards_rarity ON cards(rarity);
    ''')
    # --- display order: dated sets by release date, then promo events by name --
    cols = [c[1] for c in cur.execute('PRAGMA table_info(sets)')]
    if 'sort_order' not in cols:
        cur.execute('ALTER TABLE sets ADD COLUMN sort_order INTEGER')
    dated = [r[0] for r in cur.execute(
        'SELECT set_code FROM sets WHERE release_date IS NOT NULL ORDER BY release_date')]
    undated = sorted(cur.execute('SELECT set_code, name_en FROM sets WHERE release_date IS NULL'),
                     key=lambda r: natural_key(r[1]))
    for i, code in enumerate(dated + [c for c, _ in undated], start=1):
        cur.execute('UPDATE sets SET sort_order = ? WHERE set_code = ?', (i, code))

    con.commit()
    cur.execute('VACUUM')
    con.close()
    os.remove(DB + '.bak')

    print(f'boosters: {len(boosters)}  promos: {len(promos)} ({new_ids} new ids, next id {next_id})  '
          f'promo sets: {len(events)}')


if __name__ == '__main__':
    sys.exit(main())
