#!/usr/bin/env bash
# Weekly price update, run on the home PC by Windows Task Scheduler
# (Sundays 18:30) because Yuyutei blocks GitHub's cloud servers.
#
#   1. bring this copy of the repo up to date with GitHub
#   2. tool/scrape_prices.py --write   (stops if the safety checks fail)
#   3. tool/export_prices.py           (adds the week to data/price_history.csv)
#   4. commit the price files and push - GitHub Actions then uploads
#      prices.csv + price_history.csv to R2 (.github/workflows/weekly-prices.yml)
#
# It runs in its own clone (~/oshi_price_bot), never the working copy, so
# half-finished work there is never committed by accident.
# Every run is logged to tool/prices_out/weekly_run.log in this clone, and the
# outcome of the last run is in tool/prices_out/last_run.txt.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p tool/prices_out
LOG=tool/prices_out/weekly_run.log
STATUS=tool/prices_out/last_run.txt
exec >>"$LOG" 2>&1
echo "=== $(date '+%Y-%m-%d %H:%M %z') ==="

fail() {
  echo "FAILED: $1"
  echo "FAILED $(date '+%Y-%m-%d %H:%M') - $1" >"$STATUS"
  exit 1
}

git pull -q --ff-only origin main || fail 'could not update from GitHub'
python3 tool/scrape_prices.py --write || fail 'scrape stopped (blocked, or safety checks failed - see scrape_report.txt)'
python3 tool/export_prices.py || fail 'export refused the prices'

git add assets/holo_tcg_cards.csv assets/holo_tcg_decks.csv assets/holo_tcg_promos.csv data/price_history.csv
if git diff --cached --quiet; then
  echo 'No price changes this week.'
else
  git commit -q -m "Weekly prices $(date +%F)" || fail 'commit failed'
  git push -q origin main || fail 'push to GitHub failed'
fi
echo "OK $(date '+%Y-%m-%d %H:%M') - $(sed -n 4p tool/prices_out/scrape_report.txt)" >"$STATUS"
echo 'Done.'
