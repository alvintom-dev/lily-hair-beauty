# Lily Hair and Beauty House

Single-page marketing site for Lily Hair and Beauty House — a hair studio in Sibu Jaya, Sarawak.

Every enquiry route on the page ends in the same place: a pre-written WhatsApp message to
**+60 19-864 7308**. There is no backend, no database and no build step.

---

## Contents

- [Quick start](#quick-start)
- [Deploying](#deploying)
- [What to change](#what-to-change)
- [Before launch](#before-launch)
- [Images](#images)
- [How the page is built](#how-the-page-is-built)
- [Performance](#performance)

---

## Quick start

There is **no build step**. `index.html` is the whole site; everything else is a static asset.

You cannot open `index.html` with `file://` — the Google Maps embed and the `<picture>`
sources need a real origin. Serve the folder instead:

```bash
# any one of these
python3 -m http.server 8000
npx serve .
npx http-server -p 8000
```

Then open <http://localhost:8000>.

```
.
├── index.html                 # the entire site: markup, CSS and JS
├── 404.html                   # branded not-found page
├── _headers                   # Cloudflare Pages / Netlify cache + security headers
├── deploy.sh                  # stage dist/ and push to Cloudflare Pages
├── assets/
│   ├── lily-logo.png          # original wordmark (source of truth)
│   ├── lily-logo-220.webp     # nav + footer logo, 1x
│   ├── lily-logo-440.webp     # nav + footer logo, 2x
│   ├── favicon-96.png         # browser tab icon
│   ├── apple-touch-icon.png   # iOS home-screen icon
│   └── hero/                  # UNUSED — see "Before launch"
└── images/
    ├── hair_styles/           # the studio look set (AVIF + WebP @ 400/800/1200)
    └── h_s_*.jpeg             # UNUSED legacy stock — see "Before launch"
```

---

## Deploying

**Live at <https://lily-beauty.baratech.my/>** (Cloudflare Pages project
`lily-hair-beauty`, also reachable at `lily-hair-beauty.pages.dev`).

```bash
./deploy.sh              # stage dist/ and deploy
./deploy.sh --stage-only # stage dist/ only, no login or upload
```

There is no build step. "Staging" copies only the files that should be public into
`dist/` — the retired stock photos and the unused `assets/hero/` renders never reach a
public URL, and the script refuses to deploy if a look is missing any of its six image
variants. It reuses the `wrangler` pinned in `baratech/baratech-landing/node_modules`
when that repo is checked out alongside this one, so both sites deploy with the same
version.

Override the defaults with env vars:

```bash
PROJECT_NAME=lily-hair-beauty BRANCH=main ./deploy.sh
```

### First-time DNS

The Pages project owns the custom domain, but the CNAME lives in the `baratech.my` zone
and has to be created once:

| Field | Value |
| --- | --- |
| Type | `CNAME` |
| Name | `lily-beauty` |
| Target | `lily-hair-beauty.pages.dev` |
| Proxy | Proxied (orange cloud) |

Cloudflare issues the certificate within a minute or two of the record appearing, and the
custom domain flips from *pending* to *active*.

### Deploying somewhere else

The site is plain static files, so any host works with **no build command** and the
repository root (or `dist/` after staging) as the publish directory.

| Host | Build command | Publish directory |
| --- | --- | --- |
| Cloudflare Pages | *(none)* | `dist` |
| Vercel | *(none)* | `.` |
| Netlify | *(none)* | `.` |
| GitHub Pages | — | repository root (add an empty `.nojekyll`) |

`_headers` is read by Cloudflare Pages and Netlify. The Vercel equivalent:

```json
{
  "headers": [
    { "source": "/(images|assets)/(.*)",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }] },
    { "source": "/index.html",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=0, must-revalidate" }] }
  ]
}
```

### Custom domain

If the site moves to its own domain, update all four absolute URLs in `index.html` —
`<link rel="canonical">`, `og:url`, `og:image`, and `image` in the JSON-LD block. They
currently point at `lily-beauty.baratech.my`.

---

## What to change

All of these live in one config block near the top of the `<script>` in `index.html`:

```js
var WA = '60198647308';       // WhatsApp, international format, no '+'
var SHOW_AI_STUDIO = false;   // AI Studio section is hidden; flip to true to show it
var GSAP_MIN_WIDTH = 900;     // below this, the hero uses the built-in fallback
```

| Change | Where |
| --- | --- |
| WhatsApp number | `WA` (also update the two `tel:+60198647308` links and the visible number in the contact card + footer) |
| Services, durations, prices | `SERVICE_INFO` array |
| The six looks (names, copy, upkeep) | `LOOKS` array — drives the hero, lookbook, gallery and style preview |
| Before/after pairs and their copy | `BA` array |
| Style Finder questions | `QUIZ` array; scoring lives in `recommend()` |
| Bookable time slots | `TIMES` array |
| Address | Search `Sublot 26` — it appears in the contact card, footer, mobile menu, map sheet, map/Waze links and the JSON-LD block |
| Opening hours | Contact card marked `TO CONFIRM`, plus the JSON-LD block |

### Enabling the AI Studio

`SHOW_AI_STUDIO = false` hides that section. The three tools it contains run on **local
keyword matching only** — there is no AI backend. Turn it on only after wiring a real
service, or it will promise more than it delivers.

### The owner view

The footer link opens a panel listing enquiries captured from this browser. It is a demo of
the funnel — leads are stored in `localStorage` under `lily.leads.v1` and are visible **only
on the device that created them**. It is not a CRM and nothing is sent anywhere. Remove the
`#openOwner` button before launch if it shouldn't be public.

---

## Before launch

- [ ] **Replace the placeholder imagery.** Every photo is a studio reference set of one
      model, not Lily's clients. Three on-page notices say so — remove them as real work
      lands. Get written permission before publishing client before/after photos.
- [ ] **Fill in real prices.** Every service shows `RM —` with a `PLACEHOLDER PRICING` notice.
- [ ] **Publish opening hours.** The contact card currently says hours aren't published yet.
- [ ] **Confirm the map pin.** It resolves to Jalan Sibu Jaya, not the exact shoplot. The
      most reliable fix is to create a Google Business Profile and point the embed at the
      place ID.
- [ ] **Delete unused files** — roughly 1.3 MB of dead weight that still ships in the repo:
      - `assets/hero/` (968 KB) — superseded hero renders, referenced nowhere.
      - `images/h_s_*.jpeg` and `images/h_s_3.webp` (324 KB) — the previous stock set. These
        were removed from the page deliberately: they are scraped photos of identifiable
        people, one of them a well-known public figure on a red carpet. Publishing them on a
        commercial salon site implies those people are clients and carries a real
        rights problem. Do not put them back.
- [ ] If the site moves off `lily-beauty.baratech.my`, update the four absolute URLs in `index.html` (canonical, `og:url`, `og:image`, JSON-LD `image`).
- [ ] Decide whether the owner view stays public.

---

## Images

Every photo ships as **AVIF and WebP at 400 / 800 / 1200 px wide**, picked per device by
`<picture>` + `srcset`. Nothing is loaded from a third-party image host.

`pic()` in `index.html` generates the markup — it assumes all six files exist for a given
base name:

```
images/hair_styles/<name>-{400,800,1200}.{avif,webp}
```

To add or replace a look, drop in a portrait (4:5 works best, 1200 px wide or larger) and
regenerate the variants. Requires `cwebp`, `avifenc` (`brew install webp libavif`) and
macOS `sips`:

```bash
SRC=path/to/photo.png            # PNG or JPEG source
NAME=07-my-new-look

for W in 400 800 1200; do
  sips -Z $((W*1242/1000)) "$SRC" --out /tmp/r.png >/dev/null
  sips -z $((W*1242/1000)) $W /tmp/r.png --out /tmp/rr.png >/dev/null
  cwebp -quiet -q 72 -m 6 -sharp_yuv /tmp/rr.png -o "images/hair_styles/$NAME-$W.webp"
  avifenc --min 0 --max 63 -a end-usage=q -a cq-level=32 -a tune=ssim -s 4 -j all \
    /tmp/rr.png "images/hair_styles/$NAME-$W.avif" >/dev/null
done
```

Then add an entry to the `LOOKS` array with `file: IMG + '<NAME>'`.

---

## How the page is built

One file, no framework, no bundler. ES5-compatible JavaScript in a single IIFE.

- **Hero** — six cards scrubbed sideways as you scroll a tall sticky track. On screens
  ≥ 900 px GSAP + ScrollTrigger are loaded dynamically for the smooth scrub and parallax;
  below that a built-in `requestAnimationFrame` fallback drives the same strip, so GSAP is
  never downloaded on a phone. Card reveals use CSS + `IntersectionObserver`, so they work
  on both paths.
- **Lookbook** — the same `LOOKS` array, with a thumbnail selector. On one column the photo
  leads and the copy follows.
- **Before/after** — dragging is bound to the **handle only**. The frame itself is
  `touch-action: pan-y`, so swiping the photo scrolls the page instead of yanking the
  divider, which is the usual complaint with these sliders on mobile. The handle is a real
  `role="slider"`: arrow keys move it 2 % (10 % with Shift), Home/End jump to the ends. A
  plain tap anywhere on the frame also jumps the divider — a tap can never be a scroll.
- **Overlays** — the WhatsApp drawer, map sheet and owner view share one open/close manager
  that locks background scroll, traps focus on the close button, closes on Escape or
  backdrop click, and stacks correctly if two are opened.
- **Enquiry drawer** — slides in from the right on desktop, rises as a bottom sheet under
  680 px. The message is generated from wherever the visitor clicked, and stays editable.
- **Map** — the Google Maps iframe only loads the first time someone opens the sheet.

### Breakpoints

| Width | Behaviour |
| --- | --- |
| ≤ 600 px | Gallery 2-up, services 1 column |
| ≤ 680 px | Enquiry drawer becomes a bottom sheet |
| ≤ 900 px | Burger menu, no GSAP, hero track shortened to 360vh |
| ≥ 820 px | Before/after goes two-column and alternates sides |
| ≥ 860 px | Lookbook goes two-column |
| ≥ 1000 px | Gallery 6-up, services 3 columns, contact 4 columns |

---

## Performance

First load on desktop is roughly **150 KB**, of which GSAP is 113 KB. On mobile GSAP is
never requested, so a phone loads about **35 KB** plus one hero image.

| | |
| --- | --- |
| `index.html` | 99 KB raw, **28 KB gzipped / 23 KB brotli** |
| First hero image | 16 KB (AVIF) |
| Logo | 8 KB (WebP, down from a 158 KB PNG) |
| Third-party image requests | none |

Other things the page does on purpose:

- The stylesheet is inline, so first paint needs no extra round trip.
- Fonts load non-render-blocking (`media="print"` swapped on load) with a `<noscript>`
  fallback, and only the four weights actually used are requested.
- The first hero image is preloaded with matching `imagesrcset`/`imagesizes`, so the
  preload and the `<picture>` pick the same file instead of downloading two.
- Everything below the fold is `loading="lazy"`.
- `prefers-reduced-motion` collapses the hero to a single screen and disables transitions.

If you change the hero `sizes` attribute, change the preload's `imagesizes` to match — they
have to agree or the browser fetches two copies of the same photo.
