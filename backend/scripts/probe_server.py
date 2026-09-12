import urllib.request
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

urls = [
    'https://electrozonebd.com/',
    'https://electrozonebd.com/electrozonebd_complete_website.zip',
    'https://electrozonebd.com/backend_cpanel.zip',
    'https://electrozonebd.com/index.html',
    'https://electrozonebd.com/api',
    'https://electrozonebd.com/api/',
    'https://electrozonebd.com/api/public/index.php',
    'https://electrozonebd.com/api/health.php',
    'https://electrozonebd.com/backend/',
    'https://electrozonebd.com/backend/public/index.php',
    'https://electrozonebd.com/scratch_complete_website/',
    'https://electrozonebd.com/electrozonebd_complete_website/'
]

for u in urls:
    try:
        req = urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, context=ctx, timeout=5) as resp:
            data = resp.read(200)
            print(f"[{resp.status}] {u} -> {data[:60]}")
    except urllib.error.HTTPError as e:
        print(f"[{e.code}] {u}")
    except Exception as e:
        print(f"[ERR] {u} -> {e}")
