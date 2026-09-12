import urllib.request
import json
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

login_data = json.dumps({
    "email": "admin@electrozonebd.com",
    "password": "admin123"
}).encode('utf-8')

urls = [
    'https://electrozonebd.com/api/auth/login',
    'https://electrozonebd.com/api/auth/login.php',
    'https://electrozonebd.com/api/login',
    'https://electrozonebd.com/api/login.php'
]

headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0'
}

for url in urls:
    req = urllib.request.Request(url, data=login_data, headers=headers, method='POST')
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=8) as r:
            body = r.read().decode('utf-8', errors='ignore')
            print(f"[{r.status}] {url} -> {body}")
            break
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8', errors='ignore')
        print(f"[{e.code}] {url} -> {body[:200]}")
    except Exception as e:
        print(f"[ERR] {url} -> {e}")
