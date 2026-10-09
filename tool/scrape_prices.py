"""Fetch current card prices from Yuyutei (with Fullahead for gaps) and put
them into the three card CSVs.

Run from the project root:

    python3 tool/scrape_prices.py            # dry run: report only, no files changed
    python3 tool/scrape_prices.py --write    # also update price_jpy in the CSVs

Then, as before:  python3 tool/export_prices.py  and upload prices.csv to R2.

STATUS (2026-10-09): first version, not yet run end-to-end. Run it by hand
for a week or two and compare against the manual price update before it is
trusted to run on a schedule (GitHub Actions is the plan).

How it works
------------
1. Yuyutei (primary). One page per set: /sell/hocg/s/hbp01, /s/hsd02 ...
   plus its five promo pages. Each listing shows a card number, rarity,
   name and price. Damaged (キズ) listings are skipped.
2. Fullahead (fallback). Only for cards Yuyutei had no usable price for,
   one search per card number. ¥999,999 is their "not in circulation yet"
   placeholder and is ignored.
3. Matching. A listing is matched to our CSV rows by card number + rarity.
   If that still leaves more than one possible price (e.g. a promo that
   exists in several event versions at different prices), the card is left
   alone and listed in the report as "ambiguous" for a human to check.
4. Nothing is ever set to 0, and a card that can't be found keeps its old
   price (it's listed in the report).

Being polite
------------
- One request at a time with a pause between them (DELAY_SECONDS).
- Every page is cached for the day in tool/price_cache/<date>/ (gitignored),
  so re-running the same day doesn't download anything again.
- robots.txt is respected, and the script identifies itself honestly.
- It stops at once if a site answers "too many requests" or "forbidden".

Safety checks
-------------
With --write, the CSVs are only changed if the results look normal:
- at least MIN_MATCH_SHARE of the cards that had a price were found again, and
- no more than MAX_BIG_JUMP_SHARE of updated prices moved by more than
  BIG_JUMP_FACTOR times (up or down).
A failure usually means a site changed its layout. --force skips the checks.
"""
import argparse
import csv
import datetime
import html
import io
import os
import re
import sys
import time
import urllib.error
import urllib.request
import urllib.robotparser

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = ['holo_tcg_cards.csv', 'holo_tcg_decks.csv', 'holo_tcg_promos.csv']
CACHE_ROOT = os.path.join(ROOT, 'tool', 'price_cache')
REPORT = os.path.join(ROOT, 'tool', 'prices_out', 'scrape_report.txt')

USER_AGENT = 'OshiCollectPriceBot/0.1 (personal non-commercial card app; +https://standbyinteractive.com)'
DELAY_SECONDS = 6         # pause between live requests
TIMEOUT_SECONDS = 30

YUYUTEI = 'https://yuyu-tei.jp'
# Yuyutei groups promos into these pages rather than one per event.
YUYUTEI_EXTRA_PAGES = ['promo-100', 'promo-hbp10', 'promo-hsd10', 'promo-heb10',
                       'promo-hbd20', 'hys01', 'yell01']
FULLAHEAD = 'https://fullahead-sdbs.com'
FULLAHEAD_PLACEHOLDER = 999999

MIN_MATCH_SHARE = 0.85
BIG_JUMP_FACTOR = 5
MAX_BIG_JUMP_SHARE = 0.05


# ---------------------------------------------------------------- fetching

class Fetcher:
    """Downloads pages one at a time, slowly, with a same-day cache."""

    def __init__(self):
        self.cache_dir = os.path.join(CACHE_ROOT, datetime.date.today().isoformat())
        os.makedirs(self.cache_dir, exist_ok=True)
        self.last_request = 0.0
        self.robots = {}
        self.live_requests = 0

    def _allowed(self, url):
        site = '/'.join(url.split('/')[:3])
        if site not in self.robots:
            rp = urllib.robotparser.RobotFileParser(site + '/robots.txt')
            try:
                self._wait()
                rp.read()
            except Exception:
                rp = None   # no readable robots.txt = no stated restrictions
            self.robots[site] = rp
        rp = self.robots[site]
        return rp is None or rp.can_fetch(USER_AGENT, url)

    def _wait(self):
        gap = time.time() - self.last_request
        if gap < DELAY_SECONDS:
            time.sleep(DELAY_SECONDS - gap)
        self.last_request = time.time()

    def get(self, url, cache_name, encoding='utf-8'):
        """Return the page text, or None if it doesn't exist (404)."""
        path = os.path.join(self.cache_dir, cache_name)
        if os.path.exists(path):
            with open(path, 'rb') as f:
                data = f.read()
            return None if data == b'404' else data.decode(encoding, errors='replace')
        if not self._allowed(url):
            sys.exit(f'robots.txt asks bots not to fetch {url} - stopping.')
        self._wait()
        self.live_requests += 1
        print(f'  fetching {url}')
        req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as r:
                data = r.read()
        except urllib.error.HTTPError as e:
            if e.code == 404:
                data = b'404'
            elif e.code in (403, 429, 503):
                sys.exit(f'{url} answered {e.code} (blocked / too many requests) - stopping politely.')
            else:
                raise
        with open(path, 'wb') as f:
            f.write(data)
        return None if data == b'404' else data.decode(encoding, errors='replace')


# ---------------------------------------------------------------- parsing

def parse_price(text):
    """'19,800 円' -> 19800"""
    digits = re.sub(r'[^\d]', '', text)
    return int(digits) if digits else None


# One Yuyutei listing: the image alt text holds "<number> <rarity> <name>",
# then the price in a <strong>, and a hidden cart_kizu field (1 = damaged).
YY_LISTING = re.compile(
    r'alt="(?P<alt>[^"]+)" class="card img-fluid".*?'
    r'<strong[^>]*>\s*(?P<price>[\d,]+)\s*円\s*</strong>.*?'
    r'value="(?P<kizu>\d)" class="cart_kizu"',
    re.S)


def parse_yuyutei(page, text):
    listings = []
    for m in YY_LISTING.finditer(text):
        parts = html.unescape(m['alt']).split(' ', 2)
        if len(parts) < 3:
            continue
        number, rarity, name = parts
        if m['kizu'] != '0' or 'キズ' in name:
            continue
        listings.append({'page': page, 'number': number.upper(), 'rarity': rarity,
                         'name': name, 'price': parse_price(m['price'])})
    return listings


FA_LISTING = re.compile(
    r'<span class="itemName">(?P<name>.*?)</span>.*?'
    r'<span class="itemPrice">\s*<strong>(?P<price>[\d,]+)円</strong>',
    re.S)
FA_TOTAL = re.compile(r'全 <strong>\[(\d+)\]</strong> 商品')


def parse_fullahead(number, text, rarities):
    """Listings on a Fullahead search page that are exactly this card number."""
    listings = []
    for m in FA_LISTING.finditer(text):
        name = html.unescape(m['name'])
        if 'キズ' in name or 'まとめ' in name:
            continue
        if not re.search(r'(?<![\w-])' + re.escape(number) + r'(?![\w-])', name, re.I):
            continue
        # Whole words only, so "Spring" isn't read as rarity S.
        found = {t for t in re.findall(r'(?<![A-Za-z])[A-Z]+(?![A-Za-z])', name) if t in rarities}
        if len(found) != 1:
            continue   # rarity missing or unclear - don't guess
        price = parse_price(m['price'])
        if not price or price == FULLAHEAD_PLACEHOLDER:
            continue
        listings.append({'page': 'fullahead', 'number': number.upper(),
                         'rarity': found.pop(), 'name': name, 'price': price})
    total = FA_TOTAL.search(text)
    shown = len(FA_LISTING.findall(text))
    truncated = bool(total) and int(total.group(1)) > shown
    return listings, truncated


# ---------------------------------------------------------------- CSVs

def load_csvs():
    """Return {file name: (header, rows as dicts)}."""
    data = {}
    for name in SOURCES:
        with open(os.path.join(ROOT, 'assets', name), encoding='utf-8', newline='') as f:
            reader = csv.DictReader(f)
            data[name] = (reader.fieldnames, list(reader))
    return data


def save_csv(name, header, rows):
    out = io.StringIO()
    w = csv.DictWriter(out, fieldnames=header, lineterminator='\r\n')
    w.writeheader()
    w.writerows(rows)
    with open(os.path.join(ROOT, 'assets', name), 'w', encoding='utf-8', newline='') as f:
        f.write(out.getvalue())


# ---------------------------------------------------------------- matching

def match(rows, listings, all_rows, use_set_page):
    """Decide a price for each of `rows` from the listings.

    A price is only used when it can belong to just one of our cards: if
    several of our cards share a card number + rarity (e.g. a promo that
    came out at different events) and nothing tells them apart, the shop's
    price could be for any of them, so they're reported as ambiguous.

    Returns {card_id: price} plus a list of ambiguous card_ids.
    """
    by_key = {}
    for l in listings:
        by_key.setdefault((l['number'], l['rarity']), []).append(l)
    pages = {l['page'] for l in listings}
    extra_pages = set(YUYUTEI_EXTRA_PAGES)

    def group(r):
        # Which of our cards can't be told apart from this one. With set
        # pages, a card on its own set's page (e.g. a reprint of an hBP01
        # card in hBP08, listed on Yuyutei's hbp08 page) is told apart by it.
        page = r['set_code'].lower()
        return (r['card_number'].upper(), r['rarity'],
                page if use_set_page and page in pages else None)

    group_size = {}
    for r in all_rows:
        group_size[group(r)] = group_size.get(group(r), 0) + 1

    prices, ambiguous = {}, []
    for r in rows:
        number, rarity, page = group(r)
        cands = by_key.get((number, rarity), [])
        on_own_page = [c for c in cands if c['page'] == page] if page else []
        if on_own_page:
            cands = on_own_page
        elif page:
            # A booster/deck reprint that the shop only lists on the original
            # set's page (e.g. hSD01-016 re-released in hBP01) - same printing,
            # so the original's price applies, as long as there's only one.
            cands = [c for c in cands if not c['page'].startswith('promo')]
        elif use_set_page:
            # A promo: only the shop's promo/cheer pages, never a booster's price.
            cands = [c for c in cands if c['page'] in extra_pages]
        distinct = {c['price'] for c in cands if c['price']}
        if not distinct:
            continue
        if len(distinct) == 1 and (group_size[group(r)] == 1 or not on_own_page and page):
            prices[r['card_id']] = distinct.pop()
        else:
            ambiguous.append(r['card_id'])
    return prices, ambiguous


# ---------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--write', action='store_true', help='update price_jpy in the CSVs')
    ap.add_argument('--force', action='store_true', help='write even if the safety checks fail')
    args = ap.parse_args()

    data = load_csvs()
    all_rows = [r for _, rows in data.values() for r in rows]
    if any(not r['card_id'].strip() for r in all_rows):
        sys.exit('A row has no card_id - run tool/build_catalogue_db.py first.')
    rarities = {r['rarity'] for r in all_rows}
    fetch = Fetcher()

    # 1. Yuyutei
    print('Yuyutei:')
    set_pages = sorted({r['set_code'].lower() for name in SOURCES[:2] for r in data[name][1]})
    yy = []
    for page in set_pages + YUYUTEI_EXTRA_PAGES:
        text = fetch.get(f'{YUYUTEI}/sell/hocg/s/{page}', f'yuyutei_{page}.html')
        if text is None:
            print(f'  {page}: no such page on Yuyutei')
            continue
        found = parse_yuyutei(page, text)
        print(f'  {page}: {len(found)} listings')
        yy.extend(found)
    yy_prices, yy_ambiguous = match(all_rows, yy, all_rows, use_set_page=True)

    # 2. Fullahead, only for card numbers Yuyutei didn't settle
    missing = [r for r in all_rows if r['card_id'] not in yy_prices]
    numbers = sorted({r['card_number'].upper() for r in missing})
    print(f'Fullahead: {len(numbers)} card numbers to look up')
    fa, truncated = [], []
    for number in numbers:
        url = f'{FULLAHEAD}/shop/shopbrand.html?search={number}'
        text = fetch.get(url, f'fullahead_{number}.html', encoding='euc_jp')
        if text is None:
            continue
        found, cut = parse_fullahead(number, text, rarities)
        fa.extend(found)
        if cut:
            truncated.append(number)
    fa_prices, fa_ambiguous = match(missing, fa, all_rows, use_set_page=False)

    # 3. Combine and compare with what's in the CSVs now
    new = {**fa_prices, **yy_prices}
    source = {cid: 'Yuyutei' for cid in yy_prices}
    source.update({cid: 'Fullahead' for cid in fa_prices if cid not in yy_prices})
    ambiguous = (set(yy_ambiguous) | set(fa_ambiguous)) - set(new)

    def old_price(r):
        return int(r['price_jpy']) if r['price_jpy'].strip() else None

    had_price = [r for r in all_rows if old_price(r)]
    found_again = [r for r in had_price if r['card_id'] in new]
    changed = [r for r in all_rows if r['card_id'] in new and new[r['card_id']] != old_price(r)]
    big_jumps = [r for r in changed if old_price(r) and
                 max(new[r['card_id']], old_price(r)) / min(new[r['card_id']], old_price(r)) > BIG_JUMP_FACTOR]
    not_found = [r for r in all_rows if r['card_id'] not in new and r['card_id'] not in ambiguous]

    match_share = len(found_again) / max(len(had_price), 1)
    jump_share = len(big_jumps) / max(len(changed), 1)
    checks_ok = match_share >= MIN_MATCH_SHARE and jump_share <= MAX_BIG_JUMP_SHARE

    # 4. Report
    def line(r, extra=''):
        return f"  {r['card_id']:>5}  {r['card_number']:<12} {r['rarity']:<4} {r['set_code'][:28]:<28} {extra}"

    rep = [f'Price scrape {datetime.date.today().isoformat()}  ({fetch.live_requests} live requests)',
           f'Cards: {len(all_rows)}   priced from Yuyutei: {len(yy_prices)}   from Fullahead: {len(fa_prices)}',
           f'Previously priced cards found again: {len(found_again)}/{len(had_price)} ({match_share:.0%}, need {MIN_MATCH_SHARE:.0%})',
           f'Price changes: {len(changed)}   big jumps (>{BIG_JUMP_FACTOR}x): {len(big_jumps)} ({jump_share:.0%}, max {MAX_BIG_JUMP_SHARE:.0%})',
           f'Safety checks: {"PASSED" if checks_ok else "FAILED"}', '']
    rep.append(f'== Big jumps ({len(big_jumps)}) ==')
    rep += [line(r, f"{old_price(r)} -> {new[r['card_id']]}  ({source[r['card_id']]})") for r in big_jumps]
    rep.append(f'\n== All changes ({len(changed)}) ==')
    rep += [line(r, f"{r['price_jpy'] or 'blank'} -> {new[r['card_id']]}  ({source[r['card_id']]})") for r in changed]
    rep.append(f'\n== Ambiguous: several prices for the same number + rarity, kept old price ({len(ambiguous)}) ==')
    rep += [line(r, f"kept {r['price_jpy'] or 'blank'}") for r in all_rows if r['card_id'] in ambiguous]
    rep.append(f'\n== Not found anywhere, kept old price ({len(not_found)}) ==')
    rep += [line(r, f"kept {r['price_jpy'] or 'blank'}") for r in not_found]
    if truncated:
        rep.append('\n== Fullahead searches with more results than one page (only page 1 read) ==')
        rep.append('  ' + ', '.join(truncated))
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    with open(REPORT, 'w', encoding='utf-8') as f:
        f.write('\n'.join(rep) + '\n')
    print('\n'.join(rep[:5]))
    print(f'Full report: {os.path.relpath(REPORT, ROOT)}')

    # 5. Write
    if not args.write:
        print('Dry run - no CSVs changed. Use --write to apply.')
        return
    if not checks_ok and not args.force:
        sys.exit('Safety checks failed - CSVs NOT changed. Check the report (a site may have changed layout).')
    for name, (header, rows) in data.items():
        for r in rows:
            if r['card_id'] in new:
                r['price_jpy'] = str(new[r['card_id']])
        save_csv(name, header, rows)
    print(f'Updated {len(changed)} prices in the CSVs. Next: python3 tool/export_prices.py')


if __name__ == '__main__':
    main()
