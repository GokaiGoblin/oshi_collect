#!/usr/bin/env bash
# Weekly price update, run on the home PC by Windows Task Scheduler
# (Sundays 18:30) because Yuyutei blocks GitHub's cloud servers.
#
#   1. bring this copy of the repo up to date with GitHub
#   2. tool/scrape_prices.py --write   (stops if the safety checks fail)
#   3. tool/export_prices.py           (adds the week to data/price_history.csv)
#      tool/unpriced_report.py         (cards with no price 3 updates running,
#                                       listed in tool/prices_out/unpriced_report.txt)
#   4. commit the price files and push - GitHub Actions then uploads
#      prices.csv + price_history.csv to R2 (.github/workflows/weekly-prices.yml)
#      The push is retried, and any commit a failed earlier run left behind
#      is pushed too, so a bad week fixes itself on the next run.
#
# GitHub sign-in uses Windows' Git Credential Manager, which only works while
# WSL can run Windows programs (the WSLInterop entry in binfmt_misc). That
# entry once vanished and git sat at a "Username for github.com" prompt. The
# Windows task now re-registers it as root before starting this script, and
# git here is never allowed to prompt - it fails instead of hanging.
#
# It runs in its own clone (~/oshi_price_update), never the working copy, so
# half-finished work there is never committed by accident.
# Every run is logged to tool/prices_out/weekly_run.log in this clone, and the
# outcome of the last run is in tool/prices_out/last_run.txt.
set -uo pipefail

# Everything is inside main() so bash has read the whole script before the
# git pull below can replace this file.
main() {
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

  # Never stop and wait for a typed username/password - fail instead.
  export GIT_TERMINAL_PROMPT=0

  git pull -q --ff-only origin main || fail 'could not update from GitHub'
  python3 -u tool/scrape_prices.py --write || fail 'scrape stopped (blocked, or safety checks failed - see scrape_report.txt)'
  python3 -u tool/export_prices.py || fail 'export refused the prices'
  # Only a report - a problem here never stops the price update.
  UNPRICED=$(python3 -u tool/unpriced_report.py) || UNPRICED='Unpriced 3+ weeks: report failed'
  echo "$UNPRICED"

  git add assets/holo_tcg_cards.csv assets/holo_tcg_decks.csv assets/holo_tcg_promos.csv data/price_history.csv
  if git diff --cached --quiet; then
    echo 'No price changes this week.'
  else
    git commit -q -m "Weekly prices $(date +%F)" || fail 'commit failed'
  fi

  # Push this week's commit, plus any an earlier failed run left unpushed.
  if [ -n "$(git log --oneline origin/main..HEAD)" ]; then
    [ -e /proc/sys/fs/binfmt_misc/WSLInterop ] ||
      fail 'WSL cannot run Windows programs (GitHub sign-in) - in PowerShell run: wsl -d Ubuntu -u root sh -c "echo :WSLInterop:M::MZ::/init:PF > /proc/sys/fs/binfmt_misc/register" then run this script again'
    pushed=no
    for attempt in 1 2 3; do
      if timeout 120 git push -q origin main; then pushed=yes; break; fi
      echo "push attempt $attempt failed"
      [ "$attempt" -lt 3 ] && sleep 60
    done
    [ "$pushed" = yes ] || fail 'push to GitHub failed (3 tries)'
  fi
  echo "OK $(date '+%Y-%m-%d %H:%M') - $(sed -n 4p tool/prices_out/scrape_report.txt)   $UNPRICED" >"$STATUS"
  echo 'Done.'
}
main "$@"
exit
