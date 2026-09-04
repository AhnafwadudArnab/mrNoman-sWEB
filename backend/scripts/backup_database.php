<?php
/**
 * Database Backup Script
 * Creates automated backups of the database
 * 
 * Usage:
 * php backend/scripts/backup_database.php
 * 
 * For automated backups, add to crontab:
 * 0 2 * * * php /path/to/backend/scripts/backup_database.php
 */

require_once __DIR__ . '/../config/env.php';

class DatabaseBackup {
    private $host;
    private $dbName;
    private $username;
    private $password;
    private $backupDir;
    private $retentionDays;
    
    public function __construct() {
        $this->host = Env::get('DB_HOST', 'localhost');
        $this->dbName = Env::get('DB_NAME', 'electrobd');
        $this->username = Env::get('DB_USER', 'root');
        $this->password = Env::get('DB_PASSWORD', '');
        $this->backupDir = Env::get('BACKUP_PATH', __DIR__ . '/../../backups');
        $this->retentionDays = (int)Env::get('BACKUP_RETENTION_DAYS', 30);
    }
    
    /**
     * Create database backup
     */
    public function backup() {
        echo "Starting database backup...\n";
        
        // Ensure backup directory exists
        if (!is_dir($this->backupDir)) {
            mkdir($this->backupDir, 0755, true);
            echo "Created backup directory: {$this->backupDir}\n";
        }
        
        // Generate backup filename
        $timestamp = date('Y-m-d_H-i-s');
        $filename = "backup_{$this->dbName}_{$timestamp}.sql";
        $filepath = $this->backupDir . '/' . $filename;
        
        // Build mysqldump command
        $command = sprintf(
            'mysqldump --host=%s --user=%s --password=%s --single-transaction --routines --triggers %s > %s 2>&1',
            escapeshellarg($this->host),
            escapeshellarg($this->username),
            escapeshellarg($this->password),
            escapeshellarg($this->dbName),
            escapeshellarg($filepath)
        );
        
        // Execute backup
        exec($command, $output, $returnCode);
        
        if ($returnCode !== 0) {
            echo "✗ Backup failed!\n";
            echo "Error: " . implode("\n", $output) . "\n";
            return false;
        }
        
        // Check if file was created and has content
        if (!file_exists($filepath) || filesize($filepath) === 0) {
            echo "✗ Backup file is empty or not created\n";
            return false;
        }
        
        $filesize = $this->formatBytes(filesize($filepath));
        echo "✓ Backup created successfully: {$filename} ({$filesize})\n";
        
        // Compress backup
        $this->compressBackup($filepath);
        
        // Clean old backups
        $this->cleanOldBackups();
        
        return true;
    }
    
    /**
     * Compress backup file
     */
    private function compressBackup($filepath) {
        if (!function_exists('gzopen')) {
            echo "⚠ gzip not available, skipping compression\n";
            return false;
        }
        
        $gzFilepath = $filepath . '.gz';
        
        $fp = fopen($filepath, 'rb');
        $gzfp = gzopen($gzFilepath, 'wb9');
        
        if (!$fp || !$gzfp) {
            echo "⚠ Failed to compress backup\n";
            return false;
        }
        
        while (!feof($fp)) {
            gzwrite($gzfp, fread($fp, 1024 * 512));
        }
        
        fclose($fp);
        gzclose($gzfp);
        
        // Remove uncompressed file
        unlink($filepath);
        
        $filesize = $this->formatBytes(filesize($gzFilepath));
        echo "✓ Backup compressed: " . basename($gzFilepath) . " ({$filesize})\n";
        
        return true;
    }
    
    /**
     * Clean old backup files
     */
    private function cleanOldBackups() {
        $files = glob($this->backupDir . '/backup_*.sql*');
        $cutoffTime = time() - ($this->retentionDays * 24 * 60 * 60);
        $deletedCount = 0;
        
        foreach ($files as $file) {
            if (filemtime($file) < $cutoffTime) {
                unlink($file);
                $deletedCount++;
                echo "✓ Deleted old backup: " . basename($file) . "\n";
            }
        }
        
        if ($deletedCount === 0) {
            echo "✓ No old backups to clean (retention: {$this->retentionDays} days)\n";
        } else {
            echo "✓ Cleaned {$deletedCount} old backup(s)\n";
        }
    }
    
    /**
     * List all backups
     */
    public function listBackups() {
        $files = glob($this->backupDir . '/backup_*.sql*');
        
        if (empty($files)) {
            echo "No backups found\n";
            return;
        }
        
        echo "\nAvailable Backups:\n";
        echo str_repeat('-', 80) . "\n";
        printf("%-40s %-15s %-20s\n", "Filename", "Size", "Date");
        echo str_repeat('-', 80) . "\n";
        
        foreach ($files as $file) {
            $filename = basename($file);
            $size = $this->formatBytes(filesize($file));
            $date = date('Y-m-d H:i:s', filemtime($file));
            
            printf("%-40s %-15s %-20s\n", $filename, $size, $date);
        }
        
        echo str_repeat('-', 80) . "\n";
        echo "Total: " . count($files) . " backup(s)\n";
    }
    
    /**
     * Restore from backup
     */
    public function restore($backupFile) {
        $filepath = $this->backupDir . '/' . $backupFile;
        
        if (!file_exists($filepath)) {
            echo "✗ Backup file not found: {$backupFile}\n";
            return false;
        }
        
        echo "⚠ WARNING: This will overwrite the current database!\n";
        echo "Database: {$this->dbName}\n";
        echo "Backup: {$backupFile}\n";
        echo "Continue? (yes/no): ";
        
        $handle = fopen("php://stdin", "r");
        $line = fgets($handle);
        fclose($handle);
        
        if (trim(strtolower($line)) !== 'yes') {
            echo "Restore cancelled\n";
            return false;
        }
        
        echo "Starting restore...\n";
        
        // Decompress if needed
        $sqlFile = $filepath;
        if (substr($filepath, -3) === '.gz') {
            echo "Decompressing backup...\n";
            $sqlFile = substr($filepath, 0, -3);
            
            $gzfp = gzopen($filepath, 'rb');
            $fp = fopen($sqlFile, 'wb');
            
            while (!gzeof($gzfp)) {
                fwrite($fp, gzread($gzfp, 1024 * 512));
            }
            
            gzclose($gzfp);
            fclose($fp);
        }
        
        // Restore database
        $command = sprintf(
            'mysql --host=%s --user=%s --password=%s %s < %s 2>&1',
            escapeshellarg($this->host),
            escapeshellarg($this->username),
            escapeshellarg($this->password),
            escapeshellarg($this->dbName),
            escapeshellarg($sqlFile)
        );
        
        exec($command, $output, $returnCode);
        
        // Clean up decompressed file
        if ($sqlFile !== $filepath && file_exists($sqlFile)) {
            unlink($sqlFile);
        }
        
        if ($returnCode !== 0) {
            echo "✗ Restore failed!\n";
            echo "Error: " . implode("\n", $output) . "\n";
            return false;
        }
        
        echo "✓ Database restored successfully from: {$backupFile}\n";
        return true;
    }
    
    /**
     * Format bytes to human readable
     */
    private function formatBytes($bytes) {
        $units = ['B', 'KB', 'MB', 'GB'];
        $i = 0;
        
        while ($bytes >= 1024 && $i < count($units) - 1) {
            $bytes /= 1024;
            $i++;
        }
        
        return round($bytes, 2) . ' ' . $units[$i];
    }
}

// CLI execution
if (php_sapi_name() === 'cli') {
    $backup = new DatabaseBackup();
    
    $command = $argv[1] ?? 'backup';
    
    switch ($command) {
        case 'backup':
            $backup->backup();
            break;
            
        case 'list':
            $backup->listBackups();
            break;
            
        case 'restore':
            if (!isset($argv[2])) {
                echo "Usage: php backup_database.php restore <backup_filename>\n";
                exit(1);
            }
            $backup->restore($argv[2]);
            break;
            
        default:
            echo "Usage:\n";
            echo "  php backup_database.php backup          - Create new backup\n";
            echo "  php backup_database.php list            - List all backups\n";
            echo "  php backup_database.php restore <file>  - Restore from backup\n";
            exit(1);
    }
}
?>
