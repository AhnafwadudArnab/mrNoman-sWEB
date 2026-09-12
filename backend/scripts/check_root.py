import urllib.request
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
}

for path in ['/', '/index.html', '/api', '/api/']:
    url = f'https://electrozonebd.com{path}'
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, context=ctx, timeout=8) as r:
            body = r.read().decode('utf-8', errors='ignore')
            print(f"=== {url} ({r.status}) ===")
            print(body[:300])
    except urllib.error.HTTPError as e:
        print(f"=== {url} (HTTP {e.code}) ===")
        print(e.read().decode('utf-8', errors='ignore')[:300])
    except Exception as e:
        print(f"=== {url} (ERR: {e}) ===")
