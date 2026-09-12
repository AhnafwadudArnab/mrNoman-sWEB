import zipfile

with zipfile.ZipFile(r'c:\Website-fixing\electrozonebd_complete_website.zip', 'r') as z:
    names = z.namelist()
    print(f"Total files in zip: {len(names)}")
    critical = [
        'index.html',
        '.htaccess',
        'main.dart.js',
        'flutter.js',
        'api/.env',
        'api/public/index.php',
        'backend/.env',
        'backend/public/index.php'
    ]
    for c in critical:
        status = "OK" if c in names else "MISSING"
        print(f"[{status}] {c}")
