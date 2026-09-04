<?php
/**
 * registrations.php — legacy endpoint, redirects to the proper auth endpoints.
 * Use /api/auth/register for signup and /api/auth/login for login instead.
 */
header('Content-Type: application/json');
http_response_code(301);
echo json_encode(['message' => 'Use /api/auth/register or /api/auth/login']);
