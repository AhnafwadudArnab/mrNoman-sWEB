============================================================
            ElectroZoneBD README (Simple + Clear)
============================================================

What is this?
- ElectroZoneBD is an e-commerce website.
- Frontend: Flutter Web
- Backend: PHP API
- Database: MySQL

Current status
- Project completion: 97.8%
- Main features are working (auth, products, cart, orders, admin panel)
- Pending: live payment gateway (bKash/Nagad)

Important files
- backend/.env.example -> backend env template
- databaseMysql/ -> SQL files

------------------------------------------------------------
LOCAL RUN (VS Code Tasks)
------------------------------------------------------------

1) Start Backend
- Task name: Start Backend
- Health check: http://127.0.0.1:8080/api/health

2) Start Frontend
- Task name: Start Flutter Web
- URL: http://localhost:5000

3) Start both
- Task name: Start All (Backend + Flutter)

------------------------------------------------------------
DEPLOYMENT (SHORT VERSION)
------------------------------------------------------------

1) Database
- Create DB + DB user in hosting panel
- Import SQL from databaseMysql/

2) Backend upload
- Upload backend/ to server (example: public_html/api)
- Create backend/.env with production values
- Set strong JWT_SECRET

3) Frontend build
- Run:
  flutter build web --release --dart-define=API_URL=https://yourdomain.com/api
- Upload all files from build/web/ to public_html/

4) Final test
- Site: https://yourdomain.com
- API: https://yourdomain.com/api/health

------------------------------------------------------------
SECURITY MUST-DO
------------------------------------------------------------

- Use strong DB password
- Use strong JWT secret
- Enable SSL (https)
- Keep backend/.env protected
- Check CORS config before go-live

------------------------------------------------------------
IF SOMETHING BREAKS
------------------------------------------------------------

Check in this order:
1) PHP/hosting error logs
2) Browser console + network tab
3) DB credentials and permissions

============================================================
End of README
============================================================
