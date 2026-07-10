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
  - New carts are seeded with ~110 items OCR'd from the Listonic screenshots
    (6 active: κρεμοσάπουνο, οδοντόβουρτσες, πάπια, βούτυρο, γάλα, μανιτόμπα + 104 checked history items).
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

## What remains
1. Confirm from a phone + second device that both see the same cart.
2. Give the wife her token URL. 🎉

## Notes / decisions made
- No DB, no framework, no external assets (works offline-ish, no CDN).
- Quantity clamped to 1–999; item names ≤100 chars; HTML-escaped on render (XSS-safe).
- Deleting is the only destructive action and asks for confirmation.
- The screenshots and `vlm_client.py` in this directory were only inputs — they don't get deployed.
