<?php
require_once __DIR__ . '/../util/ApiResponse.php';

/**
 * Database Connection Utility
 * Provides database connection with error handling and query helpers
 */
class DatabaseConnection {
    private $conn;
    
    public function __construct() {
        $this->connect();
    }
    
    /**
     * Establish database connection
     */
    private function connect() {
        try {
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
            
            $this->conn = new PDO($dsn, $config['db']['user'], $config['db']['pass'], $options);
        } catch (PDOException $e) {
            error_log("Database connection error: " . $e->getMessage());
            ApiResponse::serverError('Database connection failed', 'Unable to connect to database');
        }
    }
    
    /**
     * Get the PDO connection
     */
    public function getConnection() {
        return $this->conn;
    }
    
    /**
     * Execute a query with error handling
     */
    public function query($sql, $params = []) {
        try {
            $stmt = $this->conn->prepare($sql);
            $stmt->execute($params);
            return $stmt;
        } catch (PDOException $e) {
            error_log("Database query error: " . $e->getMessage() . " | SQL: " . $sql);
            
            // Check for foreign key constraint violation
            if ($e->getCode() == '23000') {
                ApiResponse::error('Invalid reference', 'Referenced entity does not exist', 400);
            }
            
            ApiResponse::serverError('Database operation failed', 'An error occurred while processing your request');
        }
    }
    
    /**
     * Validate that a foreign key exists
     */
    public function validateForeignKey($table, $column, $value) {
        if ($value === null) {
            return true; // Allow null values
        }
        
        $sql = "SELECT COUNT(*) as count FROM {$table} WHERE {$column} = ?";
        $stmt = $this->query($sql, [$value]);
        $result = $stmt->fetch();
        
        return $result['count'] > 0;
    }
    
    /**
     * Begin a transaction
     */
    public function beginTransaction() {
        return $this->conn->beginTransaction();
    }
    
    /**
     * Commit a transaction
     */
    public function commit() {
        return $this->conn->commit();
    }
    
    /**
     * Rollback a transaction
     */
    public function rollback() {
        return $this->conn->rollBack();
    }
}
?>
