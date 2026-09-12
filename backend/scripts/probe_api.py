import urllib.request
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
}

test_urls = [
    'https://electrozonebd.com/api/public/index.php',
    'https://electrozonebd.com/api/index.php',
    'https://electrozonebd.com/api/health.php',
    'https://electrozonebd.com/api/api/health.php',
    'https://electrozonebd.com/api/public/dbtest.php',
    'https://electrozonebd.com/api/products.php',
    'https://electrozonebd.com/api/products',
    'https://electrozonebd.com/backend/public/index.php',
    'https://electrozonebd.com/backend/public/dbtest.php',
]

for url in test_urls:
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, context=ctx, timeout=8) as r:
            body = r.read().decode('utf-8', errors='ignore')
            print(f"[{r.status}] {url} -> {body[:150]}")
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8', errors='ignore')
        print(f"[{e.code}] {url} -> {body[:100]}")
    except Exception as e:
        print(f"[ERR] {url} -> {e}")
