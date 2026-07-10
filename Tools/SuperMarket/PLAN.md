# SuperMarket List — Plan

## What this is
A single-file PHP shared shopping list (no database), to be hosted at
`ammar.gr/supermarket/go.php?i=tokenID`. Each token = one cart, stored as
`data/TOKEN.json` next to the script. Anyone with the token can read/write.

## Current status
- `go.php` is **already written** (in this directory). It contains:
  - Landing page when no `?i=` token: "Νέα λίστα" button → random 8-hex token.
  - Cart page: mobile-first UI, Greek labels, coral/teal happy theme.
    - Sticky add-bar (textbox + ➕) to add items.
    - Each item row: tap circle to check off, [−] [qty textbox] [+] buttons, 🗑️ delete (with confirm).
    - Checked items live in a collapsible "✅ Στο καλάθι (N)" section, sorted alphabetically;
      tapping their circle puts them back on the active list.
    - Adding a name that already exists (case-insensitive) just un-checks the existing item
      instead of creating a duplicate.
    - "🔗 Κοινή χρήση" button: native share sheet or copy-link.
    - List refreshes when the tab regains focus (picks up edits from other phones).
  - New carts are seeded with ~50 **generic** staples, all checked (clean active
    list, instant re-adds from history). The original personal Listonic-OCR seed
    was dropped 2026-07-10 (made every new list a clone of the existing one);
    it lives on in the two real carts and in git history before commit 53b6a99.
  - Storage: JSON per token, written under `flock(LOCK_EX)`; token sanitized to `[A-Za-z0-9_-]{1,40}`.
  - `data/` is auto-created with a `.htaccess` (`Require all denied`) so carts aren't
    directly downloadable on Apache.

## Deployed ✅ (2026-07-10, server machine)
- Served by local Apache: DocumentRoot **is** `/home/ammar/public_html`, so the app
  lives at `http://127.0.0.1/supermarket/go.php` (= `ammar.gr/supermarket/go.php`).
  `~/public_html/supermarket/go.php` is a **symlink** into this repo directory.
- Fixes made during deployment:
  - `$DATA` now uses `dirname($_SERVER['SCRIPT_FILENAME'])` instead of `__DIR__` —
    `__DIR__` resolves symlinks, which would have put carts inside the git repo.
    Carts live in `~/public_html/supermarket/data/`.
  - Server PHP 8.3 has **no mbstring**: added a polyfill (iconv_strlen +
    Latin/Greek strtr lowercase map) so Greek case-insensitive dedup still works.
  - `data/.htaccess` and a dummy `data/index.html` are now (re)created on every
    hit if missing, so carts aren't browsable even if the dir pre-exists or
    .htaccess is ignored. Verified: `/supermarket/data/` and `data/*.json` → 403.
- Smoke-tested against production: seeds (112 items, 6 active), add, qty ±/set,
  toggle, uppercase-Greek re-add dedup, del — all pass; JSON on disk valid.

## Item photos ✅ (2026-07-10)
- Each item can have one photo: 📷 button in the row → file picker (camera on
  mobile); thumbnail once set; tap thumbnail → fullscreen viewer with
  «📷 Αλλαγή» / «🗑️ Διαγραφή».
- Storage stays database-free: `data/ITEMID-TOKEN.jpg`. Uploads go through
  ImageMagick `convert` (`-auto-orient -strip -resize '1000x1000>' -quality 82`,
  forced `jpg:` output, first frame only) — also validates the file is an image.
- `data/` is 403, so photos are streamed by `go.php?i=TOKEN&img=ITEMID`
  (long-cache headers; the photo mtime rides on items as `img` and cache-busts).
- Deleting an item deletes its photo; `a=imgdel` deletes just the photo.
- PHP upload limits were 2M/8M — too small for phone photos. Raised to 30M/32M
  via `~/public_html/supermarket/.htaccess` (php_value; AllowOverride All).
  **This file is not in the repo** — recreate it if the deployment moves.
- Tested in production: 3.8MB upload OK, resize to ≤1000px OK, PNG→JPG OK,
  garbage file → 422 «Μη έγκυρη εικόνα», >32M → 422 «Πολύ μεγάλο αρχείο»,
  wrong-token image fetch → 404, del/imgdel clean up the .jpg.

## List name + cover image ✅ (2026-07-10)
- Tap the header title (✏️) → prompt → `a=name` stores `name` in the cart JSON
  (≤60 chars; empty resets to the default «Λίστα Σούπερ Μάρκετ»). Shown in the
  header, the browser tab, and the share sheet.
- Round cover button left of the title: no cover → opens the picker; has cover →
  fullscreen viewer with change/delete. Reuses the item-photo machinery via the
  special id `cover` (item ids are pure hex, so no collision): file is
  `data/cover-TOKEN.jpg`, served by `?img=cover`, mtime rides on the cart as `cimg`.

## What remains
1. Confirm from a phone + second device that both see the same cart.
2. Give the wife her token URL. 🎉

## Notes / decisions made
- No DB, no framework, no external assets (works offline-ish, no CDN).
- Quantity clamped to 1–999; item names ≤100 chars; HTML-escaped on render (XSS-safe).
- Deleting is the only destructive action and asks for confirmation.
- The screenshots and `vlm_client.py` in this directory were only inputs — they don't get deployed.
