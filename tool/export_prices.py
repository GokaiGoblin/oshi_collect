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

The app ignores a file it doesn't trust, so this script refuses to write one
that would fail those checks (duplicate ids, zero/negative prices, too few rows).
"""
import csv
import datetime
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = ['holo_tcg_cards.csv', 'holo_tcg_decks.csv', 'holo_tcg_promos.csv']
OUT_DIR = os.path.join(ROOT, 'tool', 'prices_out')
OUT = os.path.join(OUT_DIR, 'prices.csv')
MIN_ROWS = 2000  # must match _minRows in lib/db/price_updates.dart


def main():
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
        f.write(f'updated,{datetime.date.today().isoformat()}\n')
        f.write('card_id,price_jpy\n')
        for cid in sorted(prices, key=int):
            f.write(f'{cid},{prices[cid]}\n')

    priced = sum(1 for v in prices.values() if v)
    print(f'Wrote {OUT}\n  {len(prices)} cards, {priced} priced, {len(prices) - priced} without a price')


if __name__ == '__main__':
    main()
