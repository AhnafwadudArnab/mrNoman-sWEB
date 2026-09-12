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

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'en-US,en;q=0.9',
    'Content-Type': 'application/json',
    'Origin': 'https://electrozonebd.com',
    'Referer': 'https://electrozonebd.com/'
}

url = 'https://electrozonebd.com/api/auth/login'
print(f"Testing POST {url}...")
req = urllib.request.Request(url, data=login_data, headers=headers, method='POST')

try:
    with urllib.request.urlopen(req, context=ctx, timeout=12) as r:
        body = r.read().decode('utf-8', errors='ignore')
        print(f"Status: {r.status}")
        print(f"Response: {body}")
except urllib.error.HTTPError as e:
    body = e.read().decode('utf-8', errors='ignore')
    print(f"HTTP Error {e.code}: {body}")
except Exception as e:
    print(f"Error: {e}")
