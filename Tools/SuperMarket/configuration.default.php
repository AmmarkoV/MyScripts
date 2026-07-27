<?php
/*
 * configuration.default.php — default knobs for the supermarket list.
 * This file is tracked in git; go.php copies it to configuration.php when
 * that doesn't exist yet. Make your local changes in configuration.php
 * (git-ignored), so they never diverge from the repo. Changes apply on the
 * next page load, no build step.
 */

/* How often (seconds) an open page checks the server for changes made
   from other phones. Lower = snappier sync, more requests. */
define('POLL_SECONDS', 30);

/* How often (seconds) the 🔄 "time since last check" label re-draws. */
define('SYNC_LABEL_SECONDS', 5);

/* List title used when a list hasn't been given a name. */
define('DEFAULT_TITLE', 'Λίστα Σούπερ Μάρκετ');

/* Where carts (TOKEN.json) and photos live. SCRIPT_FILENAME (not __DIR__)
   so a symlinked deployment keeps its data next to the *deployed* script. */
define('DATA_DIR', dirname($_SERVER['SCRIPT_FILENAME'] ?? __FILE__) . '/data');

/* Item photos: longest side in pixels after resize, and JPEG quality. */
define('IMG_MAX_DIM', 1000);
define('IMG_QUALITY', 82);

/* Limits. */
define('MAX_QTY', 999);        /* max quantity per item */
define('MAX_NAME_LEN', 100);   /* max item name length */
define('MAX_TITLE_LEN', 60);   /* max list name length */

/* Starter history for a brand-new list: these all begin checked ("in the
   basket"), so the active list is clean but re-adding a known name is instant. */
define('SEED_STAPLES', ['ψωμί','γάλα','αυγά','φέτα','γιαούρτι','βούτυρο','τυρί τοστ','ζαμπόν',
    'κοτόπουλο','κιμάς','ρύζι','μακαρόνια','φακές','φασόλια','αλεύρι','ζάχαρη',
    'αλάτι','πιπέρι','ελαιόλαδο','ξύδι','ντομάτες','πατάτες','κρεμμύδια','σκόρδο',
    'λεμόνια','μπανάνες','μήλα','πορτοκάλια','καρότα','σαλάτα','καφές','τσάι',
    'χυμός','νερό','δημητριακά','μέλι','μαρμελάδα','σοκολάτα','μπισκότα',
    'κατεψυγμένα λαχανικά','χαρτί υγείας','χαρτί κουζίνας','χαρτομάντηλα',
    'οδοντόκρεμα','σαμπουάν','σαπούνι','απορρυπαντικό πλυντηρίου','υγρό πιάτων',
    'χλωρίνη','σακούλες σκουπιδιών','αλουμινόχαρτο','λαδόκολλα']);
