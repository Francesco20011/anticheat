<?php
// api/server_stats.php
// Restituisce dati temporali (ultime 24 ore) per giocatori e bans.
// In assenza di un backend storico reale genera una serie mock basata
// sui file correnti players.json e bans.json adattando valori.

header('Content-Type: application/json');

$baseDir = dirname(__DIR__);
$dataDir = $baseDir . '/data';
$bansFile = $dataDir . '/bans.json';
$playersFile = $dataDir . '/players.json';

$currentBans = 0;
$currentPlayers = 0;

if (file_exists($bansFile)) {
    $content = file_get_contents($bansFile);
    $data = json_decode($content, true);
    if (is_array($data)) $currentBans = count($data);
}
if (file_exists($playersFile)) {
    $content = file_get_contents($playersFile);
    $data = json_decode($content, true);
    if (is_array($data)) $currentPlayers = count($data);
}

// Genera punti (uno ogni 30 minuti per 24h => 48 punti)
$points = [];
$now = time();
$interval = 1800; // 30m
$start = $now - 24*3600;
$peak = 0;
$total = 0;
$count = 0;
$banPeak = 0;

for ($t = $start; $t <= $now; $t += $interval) {
    // Mock: variazione sinusoidale + rumore leggera per players
    $progress = ($t - $start) / (24*3600);
    $base = 0.5 + 0.5 * sin($progress * 2 * M_PI - M_PI/2); // 0..1
    $players = (int)round($base * max($currentPlayers, 1) + rand(0,3));
    if ($players > $peak) $peak = $players;
    $total += $players; $count++;
    $bans = (int)round(($currentBans) * ($t - $start) / (24*3600));
    if ($bans > $banPeak) $banPeak = $bans;
    $points[] = [
        'time' => gmdate('c', $t),
        'players' => $players,
        'bans' => $bans
    ];
}
$avg = $count ? ($total / $count) : 0;

$response = [
    'data' => $points,
    'totalPlayers' => $currentPlayers,
    'totalBans' => $currentBans,
    'peakPlayers' => $peak,
    'avgPlayers' => $avg,
    'maxPlayers' => max($currentPlayers, $peak)
];

echo json_encode($response);
