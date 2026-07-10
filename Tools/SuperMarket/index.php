<?php
/* /supermarket/ → go.php, keeping the query string so /supermarket/?i=TOKEN works too. */
$qs = $_SERVER['QUERY_STRING'] ?? '';
header('Location: go.php' . ($qs !== '' ? "?$qs" : ''), true, 302);
exit;
