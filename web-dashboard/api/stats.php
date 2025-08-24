<?php
// api/stats.php
//
// Returns a JSON object containing statistics about the anti‑cheat
// system. Specifically the total number of bans and the number of
// players currently online. These values are derived from the
// JSON files written by the server scripts.

header('Content-Type: application/json');

$baseDir = dirname(__DIR__); // directory of web-dashboard
$dataDir = $baseDir . '/data';

$bansFile = $dataDir . '/bans.json';
$playersFile = $dataDir . '/players.json';

$totalBans = 0;
$totalPlayers = 0;

if (file_exists($bansFile)) {
    $content = file_get_contents($bansFile);
    $data = json_decode($content, true);
    if (is_array($data)) {
        $totalBans = count($data);
    }
}

if (file_exists($playersFile)) {
    $content = file_get_contents($playersFile);
    $data = json_decode($content, true);
    if (is_array($data)) {
        $totalPlayers = count($data);
    }
}

echo json_encode([
    'totalBans' => $totalBans,
    'totalPlayers' => $totalPlayers
]);