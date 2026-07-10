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

## What remains (to do on the server machine)
1. **Syntax check**: `php -l go.php` (dev machine had no PHP installed).
2. **Local smoke test**: `php -S localhost:8099` in this directory, then:
   - `curl 'http://localhost:8099/go.php'` → landing page HTML.
   - `curl 'http://localhost:8099/go.php?i=test1&api=1'` → JSON with the ~110 seeded items.
   - `curl -X POST -d 'a=add&n=δοκιμή' 'http://localhost:8099/go.php?i=test1'` → JSON, item added at top.
   - Same for `a=qty` (`id`,`d`=±1 or `v`=value), `a=toggle` (`id`), `a=del` (`id`).
   - Verify `data/test1.json` was created and is valid JSON; delete it after testing.
3. **Deploy**: copy `go.php` to the webroot as `/supermarket/go.php`.
   - Ensure the `supermarket/` directory is writable by the web server user
     (script mkdirs `data/` on first hit): `chown www-data` or `chmod` as appropriate.
   - If the server is nginx (not Apache), the `data/.htaccess` does nothing —
     add an nginx rule to deny `/supermarket/data/` instead.
4. **Verify in production**: open `https://ammar.gr/supermarket/go.php`, create a list,
   add/check/delete items from a phone, open the same token URL on a second device
   and confirm both see the same cart.
5. Give the wife her token URL. 🎉

## Notes / decisions made
- No DB, no framework, no external assets (works offline-ish, no CDN).
- Quantity clamped to 1–999; item names ≤100 chars; HTML-escaped on render (XSS-safe).
- Deleting is the only destructive action and asks for confirmation.
- The screenshots and `vlm_client.py` in this directory were only inputs — they don't get deployed.
