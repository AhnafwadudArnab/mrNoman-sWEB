# cPanel Package Notes

This zip is laid out for direct extraction into your cPanel domain root, such as `public_html` or `/home/<user>/<domain>/`.

After extraction, the root should contain the Flutter web files:

- `index.html`
- `main.dart.js`
- `flutter_bootstrap.js`
- `assets/`
- `canvaskit/`
- `.htaccess`
- `backend/`

The backend is included as `backend/`. Root `.htaccess` routes `/api/...` requests to `backend/public/index.php`.

Important: this repository does not currently contain a real `backend/.env` file. It includes `.env.example` only. On cPanel, create `backend/.env` using `.env.example` as the template, then set your real database, JWT, SMTP, and domain values.

Recommended post-upload checks:

1. Visit `https://yourdomain.com` and confirm the Flutter web app loads.
2. Visit `https://yourdomain.com/api/health` and confirm it returns `{"status":"ok"}`.
3. Confirm `backend/public/uploads/` is writable by PHP for product image uploads.
4. Remove or protect debug/setup endpoints such as `backend/public/install.php`, `backend/public/dbtest.php`, and `backend/public/test_local.php` after setup.
