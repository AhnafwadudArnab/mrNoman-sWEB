<?php
/**
 * Image Validation and Processing Utility
 * Validates file uploads for security and size constraints
 */

class ImageValidator {
    private $config;
    
    public function __construct() {
        $this->config = require __DIR__ . '/../config.php';
    }
    
    /**
     * Validate uploaded image file
     * @param array $file $_FILES array element
     * @return array ['valid' => bool, 'error' => string|null, 'sanitized_name' => string|null]
     */
    public function validate($file) {
        // Check if file was uploaded
        if (!isset($file['tmp_name']) || !is_uploaded_file($file['tmp_name'])) {
            return ['valid' => false, 'error' => 'No file uploaded or invalid upload'];
        }
        
        // Check for upload errors
        if ($file['error'] !== UPLOAD_ERR_OK) {
            return ['valid' => false, 'error' => $this->getUploadErrorMessage($file['error'])];
        }
        
        // Check file size
        $maxSize = $this->config['uploads']['max_size_bytes'];
        if ($file['size'] > $maxSize) {
            $maxMB = round($maxSize / (1024 * 1024), 2);
            return ['valid' => false, 'error' => "File too large. Maximum size: {$maxMB}MB"];
        }
        
        // Check if file is empty
        if ($file['size'] === 0) {
            return ['valid' => false, 'error' => 'File is empty'];
        }
        
        // Validate MIME type
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mimeType = finfo_file($finfo, $file['tmp_name']);
        finfo_close($finfo);
        
        $allowedMimes = [
            'image/jpeg',
            'image/jpg',
            'image/png',
            'image/gif',
            'image/webp'
        ];
        
        if (!in_array($mimeType, $allowedMimes)) {
            return ['valid' => false, 'error' => 'Invalid file type. Only JPG, PNG, GIF, and WebP images are allowed'];
        }
        
        // Validate file extension
        $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        $allowedExts = $this->config['uploads']['allowed_exts'];
        
        if (!in_array($ext, $allowedExts)) {
            return ['valid' => false, 'error' => 'Invalid file extension'];
        }
        
        // Validate image dimensions
        $imageInfo = getimagesize($file['tmp_name']);
        if ($imageInfo === false) {
            return ['valid' => false, 'error' => 'File is not a valid image'];
        }
        
        list($width, $height) = $imageInfo;
        
        $maxWidth = $this->config['uploads']['max_width'];
        $maxHeight = $this->config['uploads']['max_height'];
        
        if ($width > $maxWidth || $height > $maxHeight) {
            return ['valid' => false, 'error' => "Image dimensions too large. Maximum: {$maxWidth}x{$maxHeight}px"];
        }
        
        // Check for minimum dimensions (prevent 1x1 pixel attacks)
        if ($width < 10 || $height < 10) {
            return ['valid' => false, 'error' => 'Image dimensions too small. Minimum: 10x10px'];
        }
        
        // Sanitize filename
        $sanitizedName = $this->sanitizeFilename($file['name']);
        
        // Additional security: Check for embedded PHP code
        $content = file_get_contents($file['tmp_name'], false, null, 0, 1024);
        if (preg_match('/<\?php|<\?=|<script/i', $content)) {
            return ['valid' => false, 'error' => 'File contains suspicious content'];
        }
        
        return [
            'valid' => true,
            'error' => null,
            'sanitized_name' => $sanitizedName,
            'mime_type' => $mimeType,
            'width' => $width,
            'height' => $height,
            'size' => $file['size']
        ];
    }
    
    /**
     * Sanitize filename
     */
    private function sanitizeFilename($filename) {
        $ext = strtolower(pathinfo($filename, PATHINFO_EXTENSION));
        $name = pathinfo($filename, PATHINFO_FILENAME);
        
        // Remove special characters
        $name = preg_replace('/[^a-zA-Z0-9_-]/', '_', $name);
        
        // Limit length
        $name = substr($name, 0, 50);
        
        // Add timestamp to prevent collisions
        $name = $name . '_' . time() . '_' . bin2hex(random_bytes(4));
        
        return $name . '.' . $ext;
    }
    
    /**
     * Get upload error message
     */
    private function getUploadErrorMessage($errorCode) {
        switch ($errorCode) {
            case UPLOAD_ERR_INI_SIZE:
                return 'File exceeds upload_max_filesize directive in php.ini';
            case UPLOAD_ERR_FORM_SIZE:
                return 'File exceeds MAX_FILE_SIZE directive in HTML form';
            case UPLOAD_ERR_PARTIAL:
                return 'File was only partially uploaded';
            case UPLOAD_ERR_NO_FILE:
                return 'No file was uploaded';
            case UPLOAD_ERR_NO_TMP_DIR:
                return 'Missing temporary folder';
            case UPLOAD_ERR_CANT_WRITE:
                return 'Failed to write file to disk';
            case UPLOAD_ERR_EXTENSION:
                return 'File upload stopped by extension';
            default:
                return 'Unknown upload error';
        }
    }
    
    /**
     * Optimize image (compress and resize if needed)
     */
    public function optimize($sourcePath, $destinationPath, $maxWidth = 1200, $quality = 85) {
        $imageInfo = getimagesize($sourcePath);
        if ($imageInfo === false) {
            return false;
        }
        
        list($width, $height, $type) = $imageInfo;
        
        // Load image based on type
        switch ($type) {
            case IMAGETYPE_JPEG:
                $source = imagecreatefromjpeg($sourcePath);
                break;
            case IMAGETYPE_PNG:
                $source = imagecreatefrompng($sourcePath);
                break;
            case IMAGETYPE_GIF:
                $source = imagecreatefromgif($sourcePath);
                break;
            case IMAGETYPE_WEBP:
                $source = imagecreatefromwebp($sourcePath);
                break;
            default:
                return false;
        }
        
        if ($source === false) {
            return false;
        }
        
        // Calculate new dimensions
        if ($width > $maxWidth) {
            $newWidth = $maxWidth;
            $newHeight = (int)(($height / $width) * $maxWidth);
        } else {
            $newWidth = $width;
            $newHeight = $height;
        }
        
        // Create new image
        $destination = imagecreatetruecolor($newWidth, $newHeight);
        
        // Preserve transparency for PNG and GIF
        if ($type === IMAGETYPE_PNG || $type === IMAGETYPE_GIF) {
            imagealphablending($destination, false);
            imagesavealpha($destination, true);
            $transparent = imagecolorallocatealpha($destination, 255, 255, 255, 127);
            imagefilledrectangle($destination, 0, 0, $newWidth, $newHeight, $transparent);
        }
        
        // Resize
        imagecopyresampled($destination, $source, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);
        
        // Save optimized image
        $result = false;
        switch ($type) {
            case IMAGETYPE_JPEG:
                $result = imagejpeg($destination, $destinationPath, $quality);
                break;
            case IMAGETYPE_PNG:
                $result = imagepng($destination, $destinationPath, (int)(9 - ($quality / 10)));
                break;
            case IMAGETYPE_GIF:
                $result = imagegif($destination, $destinationPath);
                break;
            case IMAGETYPE_WEBP:
                $result = imagewebp($destination, $destinationPath, $quality);
                break;
        }
        
        // Free memory
        imagedestroy($source);
        imagedestroy($destination);
        
        return $result;
    }
}
?>
