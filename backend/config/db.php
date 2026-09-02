<?php
class Database {
    public $conn;
    public function getConnection() {
        $this->conn = null;
        $config = require __DIR__ . '/../config.php';
        $dsn = sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=%s',
            $config['db']['host'],
            $config['db']['port'],
            $config['db']['name'],
            $config['db']['charset']
        );
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ];
        try {
            $this->conn = new PDO($dsn, $config['db']['user'], $config['db']['pass'], $options);
        } catch (PDOException $e) {
            error_log("DB Connection error: " . $e->getMessage() .
                " | host=" . $config['db']['host'] .
                " | db=" . $config['db']['name'] .
                " | user=" . $config['db']['user']);
            http_response_code(500);
            echo json_encode(['error' => 'Database connection failed', 'detail' => $e->getMessage()]);
            exit;
        }
        return $this->conn;
    }
}
?>
