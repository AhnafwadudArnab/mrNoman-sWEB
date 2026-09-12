<?php
$zip = new ZipArchive();
if ($zip->open('c:\Website-fixing\electrozonebd_complete_website.zip') === TRUE) {
    echo "Total files in zip: " . $zip->numFiles . "\nSample files:\n";
    for ($i = 0; $i < min(25, $zip->numFiles); $i++) {
        echo " - " . $zip->getNameIndex($i) . "\n";
    }
    // Check specific critical files
    $critical = [
        'index.html',
        '.htaccess',
        'main.dart.js',
        'assets/AssetManifest.bin',
        'api/.env',
        'api/public/index.php',
        'backend/.env'
    ];
    echo "\nCritical file checks:\n";
    foreach ($critical as $c) {
        $found = ($zip->locateName($c) !== false);
        echo " [" . ($found ? "OK" : "MISSING") . "] $c\n";
    }
    $zip->close();
} else {
    echo "Failed to open zip\n";
}
