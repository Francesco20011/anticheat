<?php
// api/violations.php
//
// Returns a list of all recorded anti‑cheat violations. Each record
// contains the player's identifier, the reason and a Unix
// timestamp. This information is useful for dashboards and
// analytics. Data is stored in violations.json by the server.

header('Content-Type: application/json');

$baseDir = dirname(__DIR__);
$violationsFile = $baseDir . '/data/violations.json';

$violations = [];
if (file_exists($violationsFile)) {
    $content = file_get_contents($violationsFile);
    $data = json_decode($content, true);
    if (is_array($data)) {
        $violations = $data;
    }
}
echo json_encode($violations);