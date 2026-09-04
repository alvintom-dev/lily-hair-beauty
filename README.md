# Lily Hair and Beauty House — website

**Live at <https://lily-beauty.baratech.my/>**

A one-page website for the salon. Everything a customer clicks — a look, a service, a
gallery photo, the booking form — turns into a ready-written WhatsApp message to Lily on
**+60 19-864 7308**. Lily replies herself. There is no login and no database.

> **Before you tell customers about it:** the prices, address, hours and contact details
> are now real. The **photos** are still stand-ins, not Lily's clients. See
> [Before you promote it](#before-you-promote-it).

---

## Contents

- [Making a change](#making-a-change) — the everyday edits
- [Publishing your changes](#publishing-your-changes)
- [Adding or replacing a photo](#adding-or-replacing-a-photo)
- [Before you promote it](#before-you-promote-it)
- [If something breaks](#if-something-breaks)
- [Where things live](#where-things-live)
- [For developers](docs/TECHNICAL.md)

---

## Making a change

Almost everything you'd want to edit is in **one file: `index.html`**, in a single block
near the middle. Open it in any text editor and use **Find** (Cmd+F, or Ctrl+F on Windows)
to jump to the word in the "Search for" column.

Text between quote marks `'like this'` is what appears on the website. Change what's inside
the quotes, and leave the quotes, commas and brackets exactly as they are.

| What you want to change | Search for | What to do |
| --- | --- | --- |
| **Opening hours** | `var HOURS` | This one line is the only place. `open:9` and `close:18` use a 24-hour clock (18 = 6 PM). `shutDays:[0]` means closed on Sunday (0 = Sunday, 1 = Monday, and so on). |
| **WhatsApp number** | `var WA` | Country code, no `+`, e.g. `'60198647308'`. Then search `+60 19-864 7308` and update where it's shown to customers. |
| **Prices and services** | `var SERVICE_INFO` | One entry per service — name, price, description, who it suits. Adding or removing a service also updates the booking dropdown automatically. |
| **The six looks** | `var LOOKS` | Name, description, who it suits, upkeep. These same six feed the opening animation, the lookbook and the gallery. |
| **Before/after stories** | `var BA` | The three "Transformations" — heading, description, and the quote in italics. |
| **Booking time slots** | `var TIMES` | The times a customer can pick. |
| **The quiz questions** | `var QUIZ` | The four "Find my look" questions and their answers. If you rename a service, update `recommend()` too — it matches on service names. |
| **Address** | `Lot 8054` | It appears in five places. Change every one. |

### A worked example

Say Lily starts closing at 7 PM instead of 6 PM.

1. Open `index.html`.
2. Find `var HOURS`. You'll see:
   ```js
   var HOURS = {open:9, close:18, shutDays:[0]};
   ```
3. Change `close:18` to `close:19` — 19 is 7 PM on a 24-hour clock.
4. Save the file, then [publish](#publishing-your-changes).

That's the whole job. The hours are shown in four places — the contact card, the footer,
the map panel and the phone menu — and all four are written from that one line, so they
can't disagree with each other.

The green "Open now" / grey "Closed" badge also looks after itself. It reads Sibu's local
time, so it stays correct even for someone browsing from another country.

A few more examples:

```js
{open:10, close:20, shutDays:[]}     // open every day, 10 AM to 8 PM
{open:9,  close:18, shutDays:[0,1]}  // closed Sunday and Monday
{open:9,  close:18, shutDays:[3]}    // closed Wednesdays only
```

### Two rules

- **Don't delete a comma, quote mark or bracket.** They hold the file together. If the page
  goes blank after an edit, one of them is missing — undo and try again.
- **Look at your change before publishing it.** See [If something breaks](#if-something-breaks).

---

## Publishing your changes

This step needs the Terminal app. Open it and paste these two lines:

```bash
cd ~/workspaces/alvintom-dev/lily-hair-beauty/lily-hair-beauty-repo
./deploy.sh
```

It takes about ten seconds and prints `✓ Done` when it has finished. The website updates
straight away.

To build your changes **without** putting them online, run `./deploy.sh --stage-only`.

The first time you do this on a new computer, a browser window may open asking you to sign
in to Cloudflare. That happens once.

---

## Adding or replacing a photo

Every photo is saved in six sizes, so a phone downloads a small one and a laptop downloads
a sharp one. That's a large part of why the site loads quickly — but it does mean you can't
simply drop a JPEG into the folder.

**One command makes all six.** In Terminal:

```bash
cd ~/workspaces/alvintom-dev/lily-hair-beauty/lily-hair-beauty-repo
./add-photo.sh ~/Desktop/new-photo.jpg 07-soft-perm
```

The first part is where your photo is now. The second is a short name for it — lowercase,
words joined by hyphens, no spaces. The script tells you exactly what to do next.

**What makes a good photo:** portrait (taller than it is wide), at least 1200 pixels wide,
with the hair filling most of the frame. A wide photo will get cropped.

If the script says a tool is missing, run this once and try again:

```bash
brew install webp libavif
```

---

## Before you promote it

The site is live, but some things are still stand-ins. Work through this list before you
put the link on TikTok or a shop sign.

- [ ] **Real photos.** Every photo is a studio reference shot of one model, not a client.
      A note on the "Transformations" section says so — delete it once real work replaces
      them. **Always get written permission before publishing a client's photo.**
- [ ] **Check the map pin.** Sibu Jaya Shopping Centre 2 isn't in the mapping databases,
      so the map searches for the address rather than pointing at a known spot. The proper
      fix is a free Google Business Profile for the salon — it fixes the pin *and* makes
      the salon show up in Google Maps searches. Worth doing regardless.
- [ ] **Add a styling price.** The price list has no styling, blow-dry or updo service, but
      the "Boho Braid" look is one. It currently says "price on request". Send the price and
      it becomes a proper service.
- [ ] **Decide about "Owner view".** There's a small link at the very bottom of the page.
      It lists enquiries, but only ones made on *that same phone or laptop* — it's a
      demonstration, not a real inbox. Ask a developer to remove it if you'd rather
      customers didn't see it.

---

## If something breaks

**To check a change before publishing**, in Terminal:

```bash
cd ~/workspaces/alvintom-dev/lily-hair-beauty/lily-hair-beauty-repo
python3 -m http.server 8000
```

Then open <http://localhost:8000>. That's your edited version, visible only to you. Press
`Ctrl+C` in Terminal when you're done looking.

**The page is blank or looks wrong.** You almost certainly deleted a comma, quote mark or
bracket. Undo (Cmd+Z) until it works again.

**You already published a broken version.** Nothing is lost — every version is kept. Go to
[Cloudflare](https://dash.cloudflare.com) → Workers & Pages → `lily-hair-beauty` →
Deployments, find the last version that worked, and choose **Rollback**.

**You published but the site looks the same.** Refresh with `Cmd+Shift+R` (`Ctrl+Shift+R`
on Windows) to skip your browser's saved copy.

---

## Where things live

```
index.html      the whole website — text, layout and design in one file
404.html        the "page not found" page
images/         the photos, each saved in six sizes
assets/         the logo and the browser tab icon
deploy.sh       publishes the site
add-photo.sh    prepares a new photo in all six sizes
docs/           notes for developers
```

**Two folders that must never be published.** `images/h_s_*.jpeg` are old stock photos that
were deliberately removed: they are pictures of real, identifiable people taken from the
internet — one of them a celebrity on a red carpet. Publishing them on a salon site
suggests those people are Lily's clients, which is a genuine legal risk. `assets/hero/` is
an unused leftover. The publishing script already excludes both and will stop with an error
if one ever sneaks back in.

---

## Want Lily to edit it without a developer?

Possible, but not set up yet. Today's version needs a text editor and one Terminal command,
which is fine for a developer and not fine for anyone else.

The option — an admin screen Lily logs into from her phone to change prices, hours and text
— is written up in [docs/TECHNICAL.md](docs/TECHNICAL.md#if-lily-needs-to-edit-it-herself-future-option),
including what it would cost and what it would leave unchanged. Worth knowing up front:
**it would not touch the photos.** All six studio looks and their entries stay exactly as
they are; only where the text is stored would move.

---

Technical details — how the page is built, why it's fast, and how hosting works — are in
**[docs/TECHNICAL.md](docs/TECHNICAL.md)**.
