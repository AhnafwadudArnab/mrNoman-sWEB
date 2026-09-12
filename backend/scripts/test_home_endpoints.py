import urllib.request
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

headers = {'User-Agent': 'Mozilla/5.0'}

endpoints = [
    '/api/health',
    '/api/health.php',
    '/api/flutter_home_data',
    '/api/flutter_home_data.php',
    '/api/banners',
    '/api/categories',
    '/api/deals',
    '/api/flash_sales',
    '/api/trending',
    '/api/best_sellers',
    '/api/products'
]

for ep in endpoints:
    url = f'https://electrozonebd.com{ep}'
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, context=ctx, timeout=8) as r:
            body = r.read().decode('utf-8', errors='ignore')
            print(f"[{r.status}] {ep} -> {body[:80]}...")
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8', errors='ignore')
        print(f"[{e.code}] {ep} -> {body[:80]}...")
    except Exception as e:
        print(f"[ERR] {ep} -> {e}")
