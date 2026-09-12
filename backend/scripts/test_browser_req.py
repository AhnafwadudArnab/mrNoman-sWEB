import urllib.request
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept-Encoding': 'gzip, deflate, br'
}

req = urllib.request.Request('https://electrozonebd.com/api/public/index.php', headers=headers)
try:
    with urllib.request.urlopen(req, context=ctx, timeout=8) as r:
        print("Status:", r.status)
        print("Response:", r.read()[:500].decode('utf-8', errors='ignore'))
except urllib.error.HTTPError as e:
    print("HTTP Error:", e.code)
    print("Body:", e.read()[:500].decode('utf-8', errors='ignore'))
except Exception as e:
    print("Error:", e)
