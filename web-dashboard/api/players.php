<?php
// api/players.php
//
// Returns a list of currently connected players. This list is
// maintained by the server events module and written to
// players.json whenever players connect or disconnect.

header('Content-Type: application/json');

$baseDir = dirname(__DIR__);
$playersFile = $baseDir . '/data/players.json';

$players = [];
if (file_exists($playersFile)) {
    $content = file_get_contents($playersFile);
    $data = json_decode($content, true);
    if (is_array($data)) {
        $players = $data;
    }
}
echo json_encode($players);