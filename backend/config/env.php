<?php
/**
 * Environment Configuration Loader
 * Loads environment variables from .env file
 */

class Env {
    private static $loaded = false;
    private static $vars = [];

    /**
     * Load environment variables from .env file
     */
    public static function load($path = null) {
        if (self::$loaded) {
            return;
        }

        if ($path === null) {
            // Try common deployment locations (cPanel/public_html and local dev layouts).
            // On cPanel: backend is deployed as "api/" folder inside public_html
            // __DIR__ = /home/user/electrozonebd.com/api/config
            // So __DIR__/../.env = /home/user/electrozonebd.com/api/.env  ✅
            $candidates = [
                __DIR__ . '/../.env',                    // api/.env  (cPanel standard)
                dirname(__DIR__, 2) . '/api/.env',       // public_html/api/.env
                dirname(__DIR__, 2) . '/backend/.env',   // public_html/backend/.env
                dirname(__DIR__, 2) . '/.env',           // public_html/.env
                dirname(__DIR__, 3) . '/.env',           // one level above public_html
                getcwd() . '/.env',                      // current working dir
                '/home/' . (getenv('USER') ?: 'asiment1') . '/electrozonebd.com/api/.env', // absolute cPanel path
            ];

            foreach ($candidates as $candidate) {
                if (is_file($candidate)) {
                    $path = $candidate;
                    break;
                }
            }
        }

        if (!is_string($path) || !file_exists($path)) {
            // Do not use .env.example in runtime; only real .env or hosting env vars.
            error_log('Warning: .env file not found. Searched: ' . implode(', ', $candidates ?? []) . '. Falling back to server environment variables.');
            self::$loaded = true;
            return;
        }
        error_log('Info: .env loaded from: ' . $path);

        $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            // Skip comments
            if (strpos(trim($line), '#') === 0) {
                continue;
            }

            // Parse KEY=VALUE
            if (strpos($line, '=') !== false) {
                list($key, $value) = explode('=', $line, 2);
                $key = trim($key);
                $value = trim($value);

                // Remove quotes if present
                if (preg_match('/^(["\'])(.*)\\1$/', $value, $matches)) {
                    $value = $matches[2];
                }

                self::$vars[$key] = $value;
                
                // Also set as environment variable
                if (!getenv($key)) {
                    putenv("$key=$value");
                }
            }
        }

        self::$loaded = true;
    }

    /**
     * Get environment variable
     * @param string $key Variable name
     * @param mixed $default Default value if not found
     * @return mixed
     */
    public static function get($key, $default = null) {
        if (!self::$loaded) {
            self::load();
        }

        $value = getenv($key);
        if ($value !== false) {
            return $value;
        }

        if (isset(self::$vars[$key])) {
            return self::$vars[$key];
        }

        return $default;
    }

    /**
     * Check if environment variable exists
     */
    public static function has($key) {
        if (!self::$loaded) {
            self::load();
        }
        return isset(self::$vars[$key]) || getenv($key) !== false;
    }

    /**
     * Get all environment variables
     */
    public static function all() {
        if (!self::$loaded) {
            self::load();
        }
        return self::$vars;
    }
}

// Auto-load on include
Env::load();
?>
