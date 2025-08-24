<?php
// api/bans.php
//
// Returns the full list of bans as stored by the server in
// bans.json. The JSON structure is a dictionary keyed by player
// identifier with values containing the reason and the timestamp.

header('Content-Type: application/json');

$baseDir = dirname(__DIR__);
$bansFile = $baseDir . '/data/bans.json';

$bans = [];
if (file_exists($bansFile)) {
    $content = file_get_contents($bansFile);
    $data = json_decode($content, true);
    if (is_array($data)) {
        $bans = $data;
    }
}
echo json_encode($bans);