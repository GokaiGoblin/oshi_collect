# Oshi Collect

**A collection tracker for the hololive OFFICIAL CARD GAME (Japanese edition).**

Oshi Collect lets you browse every card, mark the ones you own, track your duplicates, and follow what your collection is worth week by week, all on your phone and without an account.

> Free, fan-made and non-commercial. Android only for now (iOS may come later).

---

## What's in the app

| | Count |
|---|---|
| **Booster sets**: hBP01 Blooming Radiance → hBP09 Volume Vortex, plus hEB01 Summer Hologram | 2,255 cards |
| **Starter Decks**: hSD01–hSD13, Live Start Decks hSD14–hSD19, and hSD20–hSD21 | 407 cards |
| **Promos**: PR packs, tournament prizes, birthday cards, anniversary and collection sets, magazine and album bonuses, collabs and more | 537 cards |
| **Total** | **3,199 cards** |

Every card has its artwork, Japanese and English names, rarity, foil status and an estimated value, with prices updated every week. hBP10 Glory Echo is listed as *coming soon*.

---

## Installing

1. Go to the [**Releases**](../../releases) page and download the latest **`Oshi.Collect.apk`** onto your Android phone.
2. Open the downloaded file. If Android asks, allow your browser or file manager to **install unknown apps** (Settings → Apps → *your browser* → Install unknown apps).
3. Tap **Install**.

**Updating:** download the newer APK and install it the same way. It installs over the old version and keeps your collection.

> **Tip:** before reinstalling or changing phones, back up your collection with **••• → Import / Export** (see [Options](#options-the--menu)).

---

## Features & how to use them

### Catalogue: browse every card

<img src="docs/screenshots/catalogue.jpg" alt="Catalogue" width="280" align="right">

The **Catalogue** tab shows every card in a 3-per-row grid.

- **Pick a set:** tap **Set ▾** (top-left) and choose from the **Booster Sets**, **Starter Decks** or **Promos** tabs. *All Catalogue* at the top shows everything; *All Boosters*, *All Decks* and *All Promos* at the top of each tab show every set of that kind, with a heading per set.
- **Search:** type in the search bar to find cards by Japanese or English name, card number (e.g. `hBP01-007`), member (searching *Suisei* also finds support cards she appears on), or set: its name (*grand prix*, *twin wafers*) or official code (*hWF01*, *hCS02*).
- **Filter:** tap the **sliders button** next to the search bar to filter by **Owned / Unowned**, **Foil**, **Rarity**, **Archetype** (colour) and **Estimated Value**.
- **Open a card:** tap any card to see its full details on the Card Profile.

<br clear="right">

### Card Profile: claim cards & count duplicates

<img src="docs/screenshots/profile.jpg" alt="Card Profile" width="280" align="right">

Tap any card in the app to open its **Card Profile**: large artwork, rarity, set, card number, both names and its estimated value, with a [trend arrow](#value-history-track-what-your-collection-is-worth) showing how the price moved since last week.

**How to claim a card (add it to your collection):**

1. Find the card in the **Catalogue** (or a set in Portfolio) and tap it.
2. Tap the gold **✦ Claim** button. It changes to **✓ Claimed**, and the card now counts towards your Portfolio.
3. Got extra copies? Use the **+ / −** buttons in the **Duplicates** panel to record how many spares you have. These show up in your Inventory.

**To unclaim**, double-tap **✓ Claimed** and confirm. Your duplicate count is kept.

Use the **‹ ›** arrows beside the artwork to step through the other cards in the same list without going back.

<br clear="right">

### Portfolio: your collection, set by set

<p>
  <img src="docs/screenshots/portfolio.jpg" alt="Portfolio: booster sets" width="280">
  <img src="docs/screenshots/portfolio-decks.jpg" alt="Portfolio: Decks view with the value summary panel" width="280">
</p>

The **Portfolio** tab opens with your **collection value**: the total for one of each card you own, how much it changed since last week's prices, and a mini chart. Tap **View history** for the full [Value History](#value-history-track-what-your-collection-is-worth).

Below it, each set shows:

- a **progress bar** with the percentage of the set you've claimed
- **cards owned / total** in the set (every rarity counts, for a truthful completion figure)
- the **estimated value** of the cards you own from that set

Use the **View ▾** menu (top-left) to switch between **Sets**, **Decks** (with their box art, as on the right above) and **Promos**, where promos are grouped into categories such as Basic PR Packs, tournament prizes, birthdays and collabs. Tap any of them to open it.

### Set view: owned & unowned at a glance

<img src="docs/screenshots/owned.jpg" alt="Portfolio set view" width="280" align="right">

Inside a set, use **All / Owned / Unowned** at the top to switch views. Cards you don't own yet are dimmed with an **UNOWNED** label, and a small **pink dot** marks cards you have duplicates of.

Switch to another set with the **Set ▾** title at the top, without going back. The search bar and **sliders button** work here too, including sorting by value.

<br clear="right">

### Value History: track what your collection is worth

<p>
  <img src="docs/screenshots/value-history.jpg" alt="Value History: chart and biggest movers" width="280">
  <img src="docs/screenshots/value-history-sets.jpg" alt="Value History: value by set" width="280">
</p>

Prices update **every Sunday**, and Oshi Collect remembers each update, so you can see how your collection's value moves over time. Open it with **View history** on the Portfolio or Inventory summary panel.

- **Value chart:** your total value at each weekly update. Switch the range with **4W / 3M / 6M / 1Y / All**; the line under the total shows the change over that range.
- **Biggest movers:** the cards in your collection that gained or lost the most since the last update.
- **By set:** what each set contributes to your total, largest first, with whether it went up or down.
- **Trend arrows** appear next to prices all through the app (card tiles, set cards, Card Profiles and the summary panels): **▲ green** = up since last week, **▼ red** = down, **▶** = no change.

### Inventory: your duplicates

<img src="docs/screenshots/inventory.jpg" alt="Inventory" width="280" align="right">

The **Inventory** tab is for your spare copies, which is handy for trading.

- The summary panel at the top shows the value of **every** spare copy you hold, with its own **View history**.
- Each set shows how many duplicates you have, their total value, and your most valuable spare.
- Inside a set, only cards with duplicates are shown. The **number badge** on the artwork is how many spares you have, and **Total Value** is that card's price × your spares.
- Tap the **sliders button** to **sort** (Card Number, Most Duplicates, Highest Total Value, Highest Single Value) or filter by Rarity, Foil and Archetype.

<br clear="right">

### Currency & prices

<img src="docs/screenshots/currency-prices.jpg" alt="Currency and prices" width="280" align="right">

**Changing your currency:**

1. Tap **•••** (top-right on any screen).
2. Tap **Currency**.
3. Choose **USD, GBP, EUR, JPY, AUD** or **CAD**. Every price in the app switches straight away.

**About the prices:**

- Prices are **estimated market values in Japanese yen**, taken from Japanese card shops (Yuyutei, with Fullahead filling gaps). Other currencies are converted using exchange rates that refresh once a day.
- **Prices update automatically every week (Sundays).** The app picks up new prices when you open it or come back to it, so no app update is needed. The **Currency** window shows the date of the prices you're seeing ("Card prices as of …").
- A card showing **"No price yet"** simply has no reliable price listed yet. It's never shown as ¥0.
- Works offline too: the app keeps the last prices it downloaded.

<br clear="right">

### Options: the ••• menu

<img src="docs/screenshots/options.jpg" alt="Options menu" width="280" align="right">

Tap **•••** in the top-right corner of any screen:

- **2-Card / 3-Card View:** bigger or smaller card grid (Catalogue).
- **Dark Mode / Light Mode:** switch themes; your choice is remembered.
- **JP Names / EN Names:** card names show in English by default; switch to the Japanese names printed on the cards.
- **Currency:** see [Currency & prices](#currency--prices).
- **Report:** spotted a wrong price, name or missing card? Send a short report straight to the developer. Reports sent from a Card Profile include that card's details automatically.
- **Import / Export:** **Export** saves your whole collection (claims and duplicates) as a `.csv` file you can keep somewhere safe. **Import** loads it back, e.g. on a new phone or after reinstalling.
- The bottom of the menu shows which **version** you have installed.

<br clear="right">

---

## Your data

- Your collection lives **only on your phone**. No account and no sign-in, and nothing about you is uploaded.
- The app connects to the internet only to load card images, card prices and exchange rates, and to send a report if you choose to.
- Android's own backup may include your collection, but **Import / Export** is the reliable way to keep a copy.

**What a report sends.** A report is sent only when you tap send, and it contains **only**:

| Sent | Example |
|---|---|
| The type of report | *General* or *Card Data* |
| The screen you sent it from | *Card Profile* |
| The card's details, if sent from a Card Profile (catalogue ID, number, set, rarity, English name) | *16 \| hBP01-007 \| hBP01 \| SEC \| Hoshimachi Suisei* |
| The app version | *1.2.0+3* |
| The message you typed | *"This price looks wrong"* |

That's all. **No** device or phone details, device IDs, location, contacts, account, or anything from your collection is collected or sent.

---

## Where the data comes from

- **Card details:** the official [hololive OFFICIAL CARD GAME card list](https://hololive-official-cardgame.com/cardlist/), plus community-maintained promo records.
- **Prices:** Japanese card shops [Yuyutei](https://yuyu-tei.jp/) and [Fullahead](https://fullahead-sdbs.com/), updated regularly.

Found a mistake? Use **••• → Report** in the app.

---

## Disclaimer

Oshi Collect is an **unofficial, fan-made app**. It is not affiliated with, endorsed by or sponsored by COVER Corporation, hololive production or the hololive OFFICIAL CARD GAME. All card names, artwork and trademarks belong to their respective owners and are used for identification only. Prices are estimates for reference and are not offers to buy or sell.

---

<p align="center">
  Designed by <b>Gokai Goblin</b><br>
  <sub>A <b>Standby Interactive</b> project</sub>
</p>
