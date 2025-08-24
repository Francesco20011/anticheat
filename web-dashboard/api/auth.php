<?php
// api/auth.php
//
// Simple authentication endpoint for the anti‑cheat dashboard. It
// accepts a POST request with `username` and `password` and returns
// a JSON object indicating success or failure. If successful a
// random token is generated and returned to the client. In a real
// application you would validate credentials against a database and
// issue a signed JWT.

header('Content-Type: application/json');

// Hardcoded credentials for demonstration purposes. Do not use
// plain text passwords in production.
$validUser = 'admin';
$validPass = 'password';

$username = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';

if ($username === $validUser && $password === $validPass) {
    // Generate a pseudo‑random token. Note: this is not secure and
    // exists solely to demonstrate client side token storage.
    $token = bin2hex(random_bytes(16));
    echo json_encode([
        'success' => true,
        'token' => $token
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Ungültige Zugangsdaten'
    ]);
}