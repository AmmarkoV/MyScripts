<?php
/*
 * go.php — Shared supermarket list, no database.
 * Each tokenID (go.php?i=TOKEN) is one shopping cart stored as data/TOKEN.json.
 * Anyone with the token can read/write the cart.
 */

error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING);

/* Local config is a git-ignored copy of the tracked defaults. The local copy
   loads first so its values win (define() keeps the first definition); the
   defaults then fill in any knob the copy is missing or doesn't exist to
   provide (read-only checkout, older copy after a git pull adds new knobs). */
if (!file_exists(__DIR__ . '/configuration.php')) {
    @copy(__DIR__ . '/configuration.default.php', __DIR__ . '/configuration.php');
}
if (file_exists(__DIR__ . '/configuration.php')) {
    require_once __DIR__ . '/configuration.php';
}
require_once __DIR__ . '/configuration.default.php';

if (function_exists('mb_internal_encoding')) {
    mb_internal_encoding('UTF-8');
} else {
    /* mbstring extension not installed: UTF-8-safe fallbacks (Latin + Greek). */
    function mb_strlen($s) {
        return function_exists('iconv_strlen') ? iconv_strlen($s, 'UTF-8') : strlen($s);
    }
    function mb_strtolower($s) {
        $s = strtr($s, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz');
        return strtr($s, ['Α'=>'α','Β'=>'β','Γ'=>'γ','Δ'=>'δ','Ε'=>'ε','Ζ'=>'ζ','Η'=>'η',
            'Θ'=>'θ','Ι'=>'ι','Κ'=>'κ','Λ'=>'λ','Μ'=>'μ','Ν'=>'ν','Ξ'=>'ξ','Ο'=>'ο',
            'Π'=>'π','Ρ'=>'ρ','Σ'=>'σ','Τ'=>'τ','Υ'=>'υ','Φ'=>'φ','Χ'=>'χ','Ψ'=>'ψ',
            'Ω'=>'ω','Ά'=>'ά','Έ'=>'έ','Ή'=>'ή','Ί'=>'ί','Ό'=>'ό','Ύ'=>'ύ','Ώ'=>'ώ',
            'Ϊ'=>'ϊ','Ϋ'=>'ϋ']);
    }
}

$DATA = DATA_DIR;
if (!is_dir($DATA)) {
    mkdir($DATA, 0775, true);
}
/* Keep carts from being browsable: deny on Apache, and an index.php so the
   directory can't be listed even where .htaccess is ignored (as on the current
   symlinked deployment, where AllowOverride doesn't cover the resolved path). */
if (!file_exists($DATA . '/.htaccess')) {
    file_put_contents($DATA . '/.htaccess', "Require all denied\n");
}
if (!file_exists($DATA . '/index.php')) {
    file_put_contents($DATA . '/index.php',
        "<?php http_response_code(403); ?>Τίποτα εδώ. 🛒\n");
}

$token = preg_replace('/[^A-Za-z0-9_-]/', '', $_GET['i'] ?? '');
$token = substr($token, 0, 40);

/* ---------- No token: landing page ---------- */
if ($token === '') {
    if (isset($_GET['new'])) {
        header('Location: go.php?i=' . bin2hex(random_bytes(4)));
        exit;
    }
    header('Content-Type: text/html; charset=utf-8');
    ?><!DOCTYPE html>
<html lang="el">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#ff7e5f">
<title><?= htmlspecialchars(DEFAULT_TITLE) ?> 🛒</title>
<style>
 body{margin:0;font-family:-apple-system,"Segoe UI",Roboto,sans-serif;
      background:linear-gradient(160deg,#ff7e5f,#feb47b);min-height:100vh;
      display:flex;align-items:center;justify-content:center;text-align:center}
 .card{background:#fffdf8;border-radius:24px;padding:36px 28px;margin:20px;
       box-shadow:0 12px 40px rgba(0,0,0,.2);max-width:340px}
 h1{margin:0 0 8px;color:#e85d3d;font-size:1.5em}
 p{color:#7a6a5f;line-height:1.5}
 a.btn{display:inline-block;margin-top:14px;background:#2bb3a3;color:#fff;
       text-decoration:none;font-weight:700;font-size:1.1em;
       padding:14px 28px;border-radius:999px;box-shadow:0 4px 14px rgba(43,179,163,.4)}
</style>
</head>
<body>
<div class="card">
  <div style="font-size:3em">🛒✨</div>
  <h1><?= htmlspecialchars(DEFAULT_TITLE) ?></h1>
  <p>Φτιάξε μια λίστα και μοιράσου τον σύνδεσμο 
     όποιος τον έχει, βλέπει και αλλάζει τη λίστα.</p>
  <a class="btn" href="go.php?new=1">➕ Νέα λίστα</a>
</div>
</body>
</html><?php
    exit;
}

$FILE = "$DATA/$token.json";

/* Path of a photo (data/ID-TOKEN.jpg), '' if the id is garbage.
   Item ids are hex; the special id 'cover' is the list's own image. */
function img_file($id) {
    global $DATA, $token;
    $id = substr(preg_replace('/[^a-z0-9]/', '', $id), 0, 16);
    return $id === '' ? '' : "$DATA/$id-$token.jpg";
}

/* Add 'img' (photo mtime, 0 = none) to every item and 'cimg' for the list's
   cover image; the mtimes double as cache-busters. */
function annotate_images($cart) {
    foreach ($cart['items'] as &$it) {
        $f = img_file($it['id']);
        $it['img'] = ($f && is_file($f)) ? filemtime($f) : 0;
    }
    unset($it);
    $f = img_file('cover');
    $cart['cimg'] = ($f && is_file($f)) ? filemtime($f) : 0;
    return $cart;
}

/* ---------- GET ?img=ITEMID: stream the item's photo ---------- */
if (isset($_GET['img'])) {
    $img = img_file($_GET['img']);
    if ($img && is_file($img)) {
        header('Content-Type: image/jpeg');
        header('Content-Length: ' . filesize($img));
        header('Cache-Control: private, max-age=31536000, immutable');
        readfile($img);
    } else {
        http_response_code(404);
    }
    exit;
}

/* ---------- GET ?rev=1: cheap "did anything change?" probe ----------
   Lock-free read; a torn read just decodes to null → rev 0 → one spare refetch. */
if (isset($_GET['rev'])) {
    $j = is_file($FILE) ? json_decode(file_get_contents($FILE), true) : null;
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode(['rev' => $j['rev'] ?? 0]);
    exit;
}

function seed_items() {
    $items = [];
    foreach (SEED_STAPLES as $n) $items[] = ['id' => new_id(), 'n' => $n, 'q' => 1, 'c' => 1];
    return $items;
}

function new_id() {
    return substr(bin2hex(random_bytes(5)), 0, 8);
}

/* Open the cart file with an exclusive lock, optionally mutate, write back. */
function with_cart($file, $mutate = null) {
    $fp = fopen($file, 'c+');
    if (!$fp) { http_response_code(500); die('Cannot open cart file'); }
    flock($fp, LOCK_EX);
    $raw = stream_get_contents($fp);
    $cart = $raw ? json_decode($raw, true) : null;
    if (!is_array($cart) || !isset($cart['items']) || !is_array($cart['items'])) {
        $cart = ['items' => seed_items()];
    }
    if ($mutate) {
        $cart = $mutate($cart);
        /* rev only moves on mutations, so pollers can probe it cheaply
           without their own reads counting as changes */
        $cart['rev'] = ($cart['rev'] ?? 0) + 1;
    }
    rewind($fp);
    ftruncate($fp, 0);
    fwrite($fp, json_encode($cart, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
    fflush($fp);
    flock($fp, LOCK_UN);
    fclose($fp);
    return $cart;
}

/* ---------- POST a=img: photo upload (resized to jpg via ImageMagick) ---------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST' &&
    (($_POST['a'] ?? '') === 'img' ||
     /* post_max_size exceeded: PHP silently drops $_POST/$_FILES */
     (empty($_POST) && (int)($_SERVER['CONTENT_LENGTH'] ?? 0) > 0))) {
    $err = '';
    $dst = img_file($_POST['id'] ?? '');
    if (empty($_POST))       $err = 'Πολύ μεγάλο αρχείο';
    elseif ($dst === '')     $err = 'Άγνωστο προϊόν';
    elseif (!isset($_FILES['f']) || $_FILES['f']['error'] !== UPLOAD_ERR_OK)
                             $err = 'Το ανέβασμα απέτυχε (πολύ μεγάλο αρχείο;)';
    else {
        exec('convert ' . escapeshellarg($_FILES['f']['tmp_name'] . '[0]')
           . ' -auto-orient -strip -resize ' . escapeshellarg(IMG_MAX_DIM . 'x' . IMG_MAX_DIM . '>')
           . ' -quality ' . (int)IMG_QUALITY . ' ' . escapeshellarg('jpg:' . $dst) . ' 2>&1', $o, $rc);
        if ($rc !== 0 || !is_file($dst)) $err = 'Μη έγκυρη εικόνα';
    }
    /* a new photo must bump rev so other phones refetch; failures must not */
    $cart = annotate_images(with_cart($FILE, $err ? null : function ($c) { return $c; }));
    if ($err) { http_response_code(422); $cart['error'] = $err; }
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($cart, JSON_UNESCAPED_UNICODE);
    exit;
}

/* ---------- API: POST mutations, return JSON cart ---------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $a  = $_POST['a']  ?? '';
    $id = $_POST['id'] ?? '';
    $cart = with_cart($FILE, function ($cart) use ($a, $id) {
        $items = $cart['items'];
        switch ($a) {
            case 'add':
                $name = trim($_POST['n'] ?? '');
                if ($name !== '' && mb_strlen($name) <= MAX_NAME_LEN) {
                    foreach ($items as &$it) {
                        if (mb_strtolower($it['n']) === mb_strtolower($name)) {
                            $it['c'] = 0; // already known: just bring it back to the list
                            $cart['items'] = $items;
                            return $cart;
                        }
                    }
                    unset($it);
                    array_unshift($items, ['id' => new_id(), 'n' => $name, 'q' => 1, 'c' => 0]);
                }
                break;
            case 'qty':
                foreach ($items as &$it) {
                    if ($it['id'] === $id) {
                        $q = isset($_POST['d']) ? $it['q'] + (int)$_POST['d'] : (int)$_POST['v'];
                        $it['q'] = max(1, min(MAX_QTY, $q));
                    }
                }
                unset($it);
                break;
            case 'toggle':
                foreach ($items as &$it) {
                    if ($it['id'] === $id) $it['c'] = $it['c'] ? 0 : 1;
                }
                unset($it);
                break;
            case 'del':
                $f = img_file($id);
                if ($f && is_file($f)) unlink($f);
                $items = array_values(array_filter($items, function ($it) use ($id) {
                    return $it['id'] !== $id;
                }));
                break;
            case 'imgdel':
                $f = img_file($id);
                if ($f && is_file($f)) unlink($f);
                break;
            case 'name':
                $n = trim($_POST['n'] ?? '');
                if ($n === '') unset($cart['name']);       // back to the default title
                elseif (mb_strlen($n) <= MAX_TITLE_LEN) $cart['name'] = $n;
                break;
        }
        $cart['items'] = $items;
        return $cart;
    });
    $cart = annotate_images($cart);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($cart, JSON_UNESCAPED_UNICODE);
    exit;
}

/* ---------- GET: page (or ?api=1 for JSON) ---------- */
$cart = annotate_images(with_cart($FILE));
if (isset($_GET['api'])) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($cart, JSON_UNESCAPED_UNICODE);
    exit;
}
header('Content-Type: text/html; charset=utf-8');

/* Link previews (WhatsApp/Viber/Messenger…): list name + cover as OG tags. */
$title  = trim($cart['name'] ?? '') !== '' ? $cart['name'] : DEFAULT_TITLE;
$active = count(array_filter($cart['items'], function ($it) { return !$it['c']; }));
$desc   = $active ? "$active προϊόντα για αγορά" : 'Όλα έτοιμα! ✨';
$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$self   = $scheme . '://' . $_SERVER['HTTP_HOST'] . $_SERVER['SCRIPT_NAME'];
?><!DOCTYPE html>
<html lang="el">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#ff7e5f">
<title>🛒 <?= htmlspecialchars($title) ?></title>
<meta property="og:type" content="website">
<meta property="og:site_name" content="<?= htmlspecialchars(DEFAULT_TITLE) ?> 🛒">
<meta property="og:title" content="🛒 <?= htmlspecialchars($title) ?>">
<meta property="og:description" content="<?= htmlspecialchars($desc) ?>">
<meta property="og:url" content="<?= htmlspecialchars("$self?i=$token") ?>">
<?php if ($cart['cimg']) { ?>
<meta property="og:image" content="<?= htmlspecialchars("$self?i=$token&img=cover&t={$cart['cimg']}") ?>">
<meta name="twitter:card" content="summary">
<?php } ?>
<style>
 *{box-sizing:border-box}
 body{margin:0;font-family:-apple-system,"Segoe UI",Roboto,sans-serif;background:#fff7ef;color:#4a3f38}
 header{background:linear-gradient(135deg,#ff7e5f,#feb47b);color:#fff;
        padding:14px 16px 12px;position:sticky;top:0;z-index:10;
        box-shadow:0 2px 12px rgba(232,93,61,.35)}
 header h1{margin:0;font-size:1.25em;display:flex;align-items:center;gap:8px}
 #coverbtn{background:rgba(255,255,255,.2);border:none;width:40px;height:40px;
        border-radius:50%;font-size:1.15em;padding:0;flex-shrink:0;overflow:hidden}
 #coverbtn img{width:100%;height:100%;object-fit:cover}
 #title{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;cursor:pointer}
 #title::after{content:' ✏️';font-size:.7em;opacity:.7}
 header .sub{font-size:.8em;opacity:.9;margin-top:2px}
 #sync{margin-left:auto;background:rgba(255,255,255,.25);border:none;color:#fff;
        border-radius:999px;padding:8px 10px;font-size:.85em;font-weight:600;
        flex-shrink:0;font-variant-numeric:tabular-nums}
 #share{background:rgba(255,255,255,.25);border:none;color:#fff;
        border-radius:999px;padding:8px 14px;font-size:.85em;font-weight:600;flex-shrink:0}
 .addbar{display:flex;gap:8px;padding:12px 12px 4px;position:sticky;top:62px;z-index:9;
         background:linear-gradient(#fff7ef 80%,rgba(255,247,239,0))}
 .addbar input{flex:1;min-width:0;font-size:1.05em;padding:12px 16px;border-radius:999px;
        border:2px solid #ffd9c4;background:#fff;outline:none}
 .addbar input:focus{border-color:#ff9d78}
 .addbar button{background:#2bb3a3;color:#fff;border:none;border-radius:999px;
        font-size:1.4em;width:52px;height:52px;flex-shrink:0;font-weight:700;
        box-shadow:0 3px 10px rgba(43,179,163,.4)}
 main{padding:8px 12px 90px;max-width:560px;margin:0 auto}
 .row{display:flex;align-items:center;gap:10px;background:#fff;border-radius:16px;
      padding:10px 12px;margin-bottom:8px;box-shadow:0 1px 4px rgba(120,80,50,.08)}
 .circ{width:34px;height:34px;border-radius:50%;border:3px solid #ffb08e;background:#fff;
       flex-shrink:0;font-size:1em;color:#fff;padding:0}
 .row.done .circ{background:#7ac74f;border-color:#7ac74f}
 .name{flex:1;min-width:0;font-size:1.05em;overflow-wrap:anywhere}
 .row.done .name{color:#b0a79e;text-decoration:line-through}
 .qty{display:flex;align-items:center;gap:4px;flex-shrink:0}
 .qty button{width:40px;height:40px;border-radius:12px;border:none;font-size:1.3em;
      font-weight:700;color:#fff;padding:0}
 .qty .minus{background:#ffa270}
 .qty .plus{background:#2bb3a3}
 .qty input{width:44px;height:40px;text-align:center;font-size:1.05em;border-radius:10px;
      border:2px solid #ffd9c4;background:#fff}
 .del{background:none;border:none;font-size:1.1em;color:#d9c6ba;flex-shrink:0;padding:6px}
 .cam{background:none;border:none;font-size:1.05em;flex-shrink:0;padding:4px;opacity:.4}
 .thumb{width:38px;height:38px;object-fit:cover;border-radius:10px;flex-shrink:0;
        border:2px solid #ffd9c4}
 #viewer{position:fixed;inset:0;background:rgba(30,20,15,.92);z-index:30;
         display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px}
 #viewer img{max-width:92vw;max-height:70vh;border-radius:16px}
 #viewer .vname{color:#fff;font-size:1.1em;font-weight:600;max-width:90vw;text-align:center}
 #viewer button{border:none;border-radius:999px;padding:12px 20px;font-size:1em;
         font-weight:600;color:#fff;margin:0 6px}
 #viewer .vchg{background:#2bb3a3}
 #viewer .vdel{background:#e85d3d}
 .sect{display:flex;align-items:center;gap:8px;width:100%;background:#ffe8d6;border:none;
       border-radius:14px;padding:12px 16px;margin:14px 0 10px;font-size:1em;
       font-weight:700;color:#a4643f}
 .sect .arrow{margin-left:auto;transition:transform .2s}
 .sect.open .arrow{transform:rotate(180deg)}
 .empty{text-align:center;color:#c7a893;padding:30px 10px;font-size:1.05em}
 #toast{position:fixed;bottom:20px;left:50%;transform:translateX(-50%);
        background:#4a3f38;color:#fff;padding:10px 20px;border-radius:999px;
        opacity:0;transition:opacity .3s;pointer-events:none;font-size:.9em;z-index:20}
</style>
</head>
<body>
<header>
  <h1><button id="coverbtn" onclick="coverClick()" aria-label="Εικόνα λίστας">🛒</button>
      <span id="title" onclick="editName()"><?= htmlspecialchars(DEFAULT_TITLE) ?></span>
      <button id="sync" onclick="refreshNow()" aria-label="Ανανέωση">🔄 τώρα</button>
      <button id="share" onclick="share()"><?= htmlspecialchars(SHARE_LABEL) ?></button></h1>
  <div class="sub" id="counter"></div>
</header>

<div class="addbar">
  <input id="newname" type="text" placeholder="Πρόσθεσε προϊόν... 🍅" maxlength="<?= (int)MAX_NAME_LEN ?>"
         onkeydown="if(event.key==='Enter')addItem()">
  <button onclick="addItem()" aria-label="Προσθήκη">＋</button>
</div>

<main>
  <div id="list"></div>
  <button class="sect" id="donehdr" onclick="toggleDone()">
     ✅ Στο καλάθι <span id="donecount"></span><span class="arrow">▼</span>
  </button>
  <div id="donelist" style="display:none"></div>
</main>

<div id="toast"></div>
<input type="file" id="imgfile" accept="image/*" style="display:none">
<div id="viewer" style="display:none" onclick="closeViewer()">
  <div class="vname" id="vname"></div>
  <img id="vimg" alt="">
  <div>
    <button class="vchg" onclick="event.stopPropagation();pickImg(VIEWID)">📷 Αλλαγή</button>
    <button class="vdel" onclick="event.stopPropagation();delImg(VIEWID)">🗑️ Διαγραφή</button>
  </div>
</div>

<script>
const TOKEN = <?= json_encode($token) ?>;
const DEFTITLE = <?= json_encode(DEFAULT_TITLE, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP) ?>;
const MAXQ = <?= (int)MAX_QTY ?>;
let CART = <?= json_encode($cart, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP) ?>;
let showDone = false;

function esc(s){const d=document.createElement('div');d.textContent=s;return d.innerHTML;}

function toast(msg){
  const t=document.getElementById('toast');
  t.textContent=msg;t.style.opacity=1;
  clearTimeout(t._h);t._h=setTimeout(()=>t.style.opacity=0,1800);
}

async function post(data){
  try{
    const fd=new FormData();
    for(const k in data)fd.append(k,data[k]);
    const r=await fetch('go.php?i='+encodeURIComponent(TOKEN),{method:'POST',body:fd});
    if(!r.ok)throw 0;
    CART=await r.json();
    render();
    synced();
  }catch(e){OFFLINE=true;updSync();toast('⚠️ Πρόβλημα σύνδεσης, δοκίμασε ξανά');}
}

/* ----- auto refresh: poll a tiny rev counter, refetch only on change ----- */
let SYNCAT=Date.now(), OFFLINE=false;
function synced(){SYNCAT=Date.now();OFFLINE=false;updSync();}
function updSync(){
  const s=Math.floor((Date.now()-SYNCAT)/1000);
  const t=s<10?'τώρα':s<60?s+'″':s<3600?Math.floor(s/60)+'′':Math.floor(s/3600)+'ω';
  document.getElementById('sync').textContent=(OFFLINE?'⚠️':'🔄')+' '+t;
}
async function poll(){
  if(document.hidden)return;
  /* don't yank a qty box out from under someone mid-edit */
  if(document.activeElement&&document.activeElement.closest&&
     document.activeElement.closest('.qty'))return;
  const base='go.php?i='+encodeURIComponent(TOKEN);
  try{
    const j=await(await fetch(base+'&rev=1')).json();
    if(j.rev!==(CART.rev||0)){
      CART=await(await fetch(base+'&api=1')).json();
      render();
    }
    synced();
  }catch(e){OFFLINE=true;updSync();}
}
function refreshNow(){poll().then(()=>{if(!OFFLINE)toast('✅ Ενημερώθηκε!');});}
setInterval(poll,<?= (int)POLL_SECONDS * 1000 ?>);
setInterval(updSync,<?= (int)SYNC_LABEL_SECONDS * 1000 ?>);

function imgURL(it){
  return 'go.php?i='+encodeURIComponent(TOKEN)+'&img='+it.id+'&t='+it.img;
}
function rowHTML(it){
  const done=it.c?' done':'';
  const qty=it.c?'':`
    <span class="qty">
      <button class="minus" onclick="qty('${it.id}',-1)">−</button>
      <input type="number" inputmode="numeric" min="1" max="${MAXQ}" value="${it.q}"
             onchange="qtySet('${it.id}',this.value)">
      <button class="plus" onclick="qty('${it.id}',1)">＋</button>
    </span>`;
  const photo=it.img
    ? `<img class="thumb" src="${imgURL(it)}" onclick="viewImg('${it.id}')" alt="">`
    : `<button class="cam" onclick="pickImg('${it.id}')" aria-label="Φωτογραφία">📷</button>`;
  return `<div class="row${done}">
    <button class="circ" onclick="toggle('${it.id}')">${it.c?'✓':''}</button>
    ${photo}
    <span class="name">${esc(it.n)}${it.c&&it.q>1?' ×'+it.q:''}</span>
    ${qty}
    <button class="del" onclick="del('${it.id}',this)">🗑️</button>
  </div>`;
}

function listName(){return CART.name||DEFTITLE;}
function render(){
  document.getElementById('title').textContent=listName();
  document.title='🛒 '+listName();
  document.getElementById('coverbtn').innerHTML=CART.cimg
    ? `<img src="go.php?i=${encodeURIComponent(TOKEN)}&img=cover&t=${CART.cimg}" alt="">`
    : '🛒';
  const items=CART.items;
  const todo=items.filter(i=>!i.c);
  const done=items.filter(i=>i.c)
                  .slice().sort((a,b)=>a.n.localeCompare(b.n,'el'));
  document.getElementById('list').innerHTML =
     todo.length ? todo.map(rowHTML).join('')
                 : '<div class="empty">Η λίστα είναι άδεια! 🎉<br>Πρόσθεσε κάτι από πάνω ⬆️</div>';
  document.getElementById('donelist').innerHTML = done.map(rowHTML).join('');
  document.getElementById('donecount').textContent = '('+done.length+')';
  document.getElementById('counter').textContent =
     todo.length ? todo.length+' προϊόντα για αγορά' : 'Όλα έτοιμα! ✨';
}

function addItem(){
  const inp=document.getElementById('newname');
  const n=inp.value.trim();
  if(!n)return;
  inp.value='';inp.focus();
  post({a:'add',n:n});
}
function qty(id,d){post({a:'qty',id:id,d:d});}
function qtySet(id,v){post({a:'qty',id:id,v:v});}
function toggle(id){post({a:'toggle',id:id});}
function del(id,btn){
  const name=btn.parentNode.querySelector('.name').textContent;
  if(confirm('Διαγραφή «'+name+'» ;'))post({a:'del',id:id});
}
let IMGID=null, VIEWID=null;
function pickImg(id){
  IMGID=id;
  document.getElementById('imgfile').click();
}
document.getElementById('imgfile').addEventListener('change',async function(){
  const file=this.files[0];
  this.value='';
  if(!file||!IMGID)return;
  toast('⏳ Ανέβασμα φωτογραφίας...');
  try{
    const fd=new FormData();
    fd.append('a','img');fd.append('id',IMGID);fd.append('f',file);
    const r=await fetch('go.php?i='+encodeURIComponent(TOKEN),{method:'POST',body:fd});
    const c=await r.json();
    CART=c;render();closeViewer();synced();
    toast(c.error?'⚠️ '+c.error:'📷 Η φωτογραφία ανέβηκε!');
  }catch(e){toast('⚠️ Πρόβλημα σύνδεσης, δοκίμασε ξανά');}
});
function viewImg(id){
  let name,t;
  if(id==='cover'){name=listName();t=CART.cimg;}
  else{
    const it=CART.items.find(i=>i.id===id);
    if(!it)return;
    name=it.n;t=it.img;
  }
  if(!t)return;
  VIEWID=id;
  document.getElementById('vname').textContent=name;
  document.getElementById('vimg').src=
    'go.php?i='+encodeURIComponent(TOKEN)+'&img='+id+'&t='+t;
  document.getElementById('viewer').style.display='flex';
}
function coverClick(){CART.cimg?viewImg('cover'):pickImg('cover');}
function editName(){
  const v=prompt('Όνομα λίστας:',CART.name||'');
  if(v!==null)post({a:'name',n:v.trim()});
}
function closeViewer(){
  document.getElementById('viewer').style.display='none';
  VIEWID=null;
}
function delImg(id){
  if(confirm('Διαγραφή φωτογραφίας;')){closeViewer();post({a:'imgdel',id:id});}
}
function toggleDone(){
  showDone=!showDone;
  document.getElementById('donelist').style.display=showDone?'':'none';
  document.getElementById('donehdr').classList.toggle('open',showDone);
}
function share(){
  const url=location.origin+location.pathname+'?i='+encodeURIComponent(TOKEN);
  /* navigator.share / navigator.clipboard only exist on HTTPS or localhost,
     so fall through: share sheet → clipboard → execCommand → show the link */
  if(navigator.share){
    navigator.share({title:listName()+' 🛒',url:url}).catch(()=>{});
    return;
  }
  if(navigator.clipboard&&navigator.clipboard.writeText){
    navigator.clipboard.writeText(url)
      .then(()=>toast('📋 Ο σύνδεσμος αντιγράφηκε!'),()=>showLink(url));
    return;
  }
  const ta=document.createElement('textarea');
  ta.value=url;ta.style.position='fixed';ta.style.opacity='0';
  document.body.appendChild(ta);ta.select();
  let ok=false;
  try{ok=document.execCommand('copy');}catch(e){}
  ta.remove();
  if(ok)toast('📋 Ο σύνδεσμος αντιγράφηκε!');
  else showLink(url);
}
function showLink(url){prompt('Αντίγραψε τον σύνδεσμο:',url);}

render();
updSync();
/* refresh when returning to the tab, so shared edits show up */
document.addEventListener('visibilitychange',()=>{if(!document.hidden)poll();});
</script>
</body>
</html>
