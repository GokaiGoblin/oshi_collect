"""List released cards that have had no price for 3 weekly updates in a row.

Run from the project root, after tool/export_prices.py:
    python3 tool/unpriced_report.py

New cards often take a week or two to get a price, but 3 empty updates in a
row usually means something's wrong - e.g. a wrong card number or rarity, or
a listing the price sources name differently.

Reads data/price_history.csv (one block of changed prices per update) and the
app's catalogue database (assets/db/holo_catalogue.db) to know which cards
are out. A card counts once its set is shown in the app and was released
on or before the first of the 3 updates (promo events have no date and always
count). Cards not in the database yet are skipped.

Writes tool/prices_out/unpriced_report.txt and prints a one-line summary
("Unpriced 3+ weeks: N") that weekly_prices.sh adds to last_run.txt.
"""
import csv
import os
import sqlite3

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HISTORY = os.path.join(ROOT, 'data', 'price_history.csv')
DB = os.path.join(ROOT, 'assets', 'db', 'holo_catalogue.db')
OUT = os.path.join(ROOT, 'tool', 'prices_out', 'unpriced_report.txt')
WEEKS = 3


def main():
    # card_id -> {date: price text}, only for dates where the price changed
    with open(HISTORY, encoding='utf-8', newline='') as f:
        rows = list(csv.DictReader(f))
    dates = sorted({r['date'] for r in rows})
    changes = {}
    for r in rows:
        changes.setdefault(int(r['card_id']), {})[r['date']] = r['price_jpy']

    db = sqlite3.connect(DB)
    cards = db.execute('''
        SELECT cards.card_id, cards.card_number, cards.rarity, sets.name_en,
               sets.is_available, COALESCE(sets.release_date, '')
        FROM cards JOIN sets ON cards.set_code = sets.set_code
        ORDER BY sets.sort_order, cards.card_id''').fetchall()

    found = []
    if len(dates) >= WEEKS:
        first_of_window = dates[-WEEKS]
        for cid, number, rarity, set_name, available, released in cards:
            if not available or (released and released > first_of_window):
                continue
            # Price on each update date = the last change on or before it.
            price, streak, history = '', 0, changes.get(cid, {})
            per_date = []
            for d in dates:
                price = history.get(d, price)
                per_date.append(price)
            for p in reversed(per_date):
                if p:
                    break
                streak += 1
            if streak >= WEEKS:
                found.append((cid, number, rarity, set_name, streak))

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8') as f:
        f.write(f'Released cards with no price for {WEEKS}+ updates in a row\n')
        f.write(f'Updates checked: {", ".join(dates[-WEEKS:]) or "none"}\n')
        if len(dates) < WEEKS:
            f.write(f'(only {len(dates)} updates so far - nothing to check yet)\n')
        f.write(f'{len(found)} card(s)\n\n')
        for cid, number, rarity, set_name, streak in sorted(found, key=lambda c: -c[4]):
            f.write(f'{cid:>6}  {number:<11} {rarity:<4} {set_name[:34]:<34} {streak} updates\n')
    print(f'Unpriced {WEEKS}+ weeks: {len(found)}')


if __name__ == '__main__':
    main()
