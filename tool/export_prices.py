"""Write the live price file the app downloads from R2.

Run from the project root:   python3 tool/export_prices.py

Reads every card's price from the three card CSVs (boosters, decks, promos)
and writes tool/prices_out/prices.csv:

    updated,2026-10-08
    card_id,price_jpy
    1,680
    1051,            <- blank = no price found (never 0)

Upload that file to R2 as  data/prices.csv  - the app picks it up next time
it's opened (within the hour, see lib/db/price_updates.dart). No new APK is
needed for price changes.

It also adds this update to data/price_history.csv (kept in git, uploaded to
R2 as data/price_history.csv), which the app uses for the portfolio value
chart and the up/down markers. Only prices that CHANGED are recorded:

    date,card_id,price_jpy
    2026-10-08,1,680          <- the first date lists every priced card
    2026-10-18,4,19800        <- later dates list just the changes
    2026-10-18,1051,          <- blank = the card lost its price

Re-running on the same date replaces that date's rows, so it's safe to repeat.
--date YYYY-MM-DD records the update under another date (used once, to seed
the history with the 2026-10-08 prices).

The app ignores a file it doesn't trust, so this script refuses to write one
that would fail those checks (duplicate ids, zero/negative prices, too few rows).
"""
import argparse
import csv
import datetime
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = ['holo_tcg_cards.csv', 'holo_tcg_decks.csv', 'holo_tcg_promos.csv']
OUT_DIR = os.path.join(ROOT, 'tool', 'prices_out')
OUT = os.path.join(OUT_DIR, 'prices.csv')
HISTORY = os.path.join(ROOT, 'data', 'price_history.csv')
MIN_ROWS = 2000  # must match _minRows in lib/db/price_updates.dart


def update_history(prices, date):
    """Record in HISTORY each price that differs from its last recorded value."""
    rows = []
    if os.path.exists(HISTORY):
        with open(HISTORY, encoding='utf-8', newline='') as f:
            rows = [r for r in csv.DictReader(f) if r['date'] != date]
    if any(r['date'] > date for r in rows):
        sys.exit(f'{HISTORY} already has dates after {date} - refusing to rewrite the past.')

    last = {}
    for r in rows:   # file is in date order, so later rows win
        last[r['card_id']] = r['price_jpy']
    added = [{'date': date, 'card_id': cid, 'price_jpy': p}
             for cid, p in sorted(prices.items(), key=lambda kv: int(kv[0]))
             if last.get(cid, '') != p]

    os.makedirs(os.path.dirname(HISTORY), exist_ok=True)
    with open(HISTORY, 'w', encoding='utf-8', newline='\n') as f:
        w = csv.DictWriter(f, fieldnames=['date', 'card_id', 'price_jpy'], lineterminator='\n')
        w.writeheader()
        w.writerows(rows + added)
    return len(added)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--date', default=datetime.date.today().isoformat(),
                    help='date to record this update under (default: today)')
    args = ap.parse_args()
    datetime.date.fromisoformat(args.date)   # fail early on a typo

    prices = {}
    for name in SOURCES:
        with open(os.path.join(ROOT, 'assets', name), encoding='utf-8-sig', newline='') as f:
            for r in csv.DictReader(f):
                cid = r['card_id'].strip()
                if not cid:
                    sys.exit(f'{name}: a row has no card_id - run tool/build_catalogue_db.py first.')
                if cid in prices:
                    sys.exit(f'card_id {cid} appears twice ({name}) - ids must be unique.')
                p = r['price_jpy'].strip()
                if p:
                    value = float(p)
                    if value <= 0:
                        sys.exit(f'card_id {cid} has price {p} - use blank for "no price", never 0.')
                    p = str(int(value)) if value == int(value) else str(value)
                prices[cid] = p

    if len(prices) < MIN_ROWS:
        sys.exit(f'Only {len(prices)} cards - the app would reject this file.')

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(f'updated,{args.date}\n')
        f.write('card_id,price_jpy\n')
        for cid in sorted(prices, key=int):
            f.write(f'{cid},{prices[cid]}\n')

    priced = sum(1 for v in prices.values() if v)
    print(f'Wrote {OUT}\n  {len(prices)} cards, {priced} priced, {len(prices) - priced} without a price')
    changes = update_history(prices, args.date)
    print(f'Updated {os.path.relpath(HISTORY, ROOT)}: {changes} price changes recorded for {args.date}')


if __name__ == '__main__':
    main()
