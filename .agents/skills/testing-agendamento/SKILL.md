# Testing — Agendamento App (Flutter + Go + PostgreSQL)

## Overview
Full-stack appointment scheduling app: Flutter web frontend, Go REST API backend, PostgreSQL database. All containerized with Docker.

## Environment Setup

### Prerequisites
- Flutter SDK (channel stable, web enabled)
- Go 1.22+
- Docker & Docker Compose
- PostgreSQL client (for direct DB queries if needed)

### Start Services

```bash
# 1. Start PostgreSQL via Docker
docker run -d --name agendamento-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=agendamento \
  -p 5432:5432 postgres:16-alpine

# 2. Start Go backend
cd backend
export DB_HOST=localhost DB_PORT=5432 DB_USER=postgres DB_PASSWORD=postgres DB_NAME=agendamento DB_SSLMODE=disable
go run cmd/api/main.go &
# Verify: curl http://localhost:8080/health → {"status":"ok"}

# 3. Build & serve Flutter web
cd ..
flutter build web
# Serve with any HTTP server on port 3000
python3 -m http.server 3000 --directory build/web &
```

Alternatively, use `docker compose up --build` for all services at once.

### Create Test Data

```bash
# Register regular user
curl -s -X POST http://localhost:8080/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"name":"Test User","email":"test@test.com","password":"Test1234!"}'

# Register admin user
curl -s -X POST http://localhost:8080/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"name":"Admin User","email":"admin@test.com","password":"admin123"}'

# Promote to admin via SQL
PGPASSWORD=postgres psql -h localhost -U postgres -d agendamento \
  -c "UPDATE users SET is_admin = TRUE WHERE email = 'admin@test.com';"

# Create time slots as admin
ADMIN_TOKEN=$(curl -s http://localhost:8080/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@test.com","password":"admin123"}' | jq -r .token)

curl -s -X POST http://localhost:8080/api/admin/slots \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"date":"2026-05-05","start_time":"09:00","end_time":"09:30"}'
```

## API Testing (curl)

Key test patterns:

| Test | Endpoint | Expected |
|------|----------|----------|
| Register | POST /api/auth/register | 201, JWT in response, no password_hash |
| Duplicate register | POST /api/auth/register | 409 conflict |
| Login | POST /api/auth/login | 200 with token |
| Wrong password | POST /api/auth/login | 401 |
| No token | GET /api/slots | 401 |
| Non-admin on admin route | GET /api/admin/appointments | 403 |
| Book appointment | POST /api/appointments | 201 |
| Double booking | POST /api/appointments (same slot) | 409 |
| Cancel other's appointment | DELETE /api/appointments/{id} | 403 |
| Admin users list | GET /api/admin/users | 200, no password_hash |

## UI Testing (Browser)

Test flow:
1. Open http://localhost:3000
2. Verify login screen has pink Material 3 theme, email/password fields, social login buttons
3. Click "Cadastre-se" → fill registration form (nome, email, senha, confirmar senha)
4. After registration → calendar screen should render with pt_BR locale
5. Click a future date → time slots screen with available/occupied slots
6. Click "Agendar" → confirmation screen with date/time → "Confirmar" → success dialog
7. Check "Meus Agendamentos" (icon in top bar)
8. Logout → login as admin → verify "Painel Admin" dashboard shows
9. Check "Agendamentos" and "Gerenciar Horários" admin screens

## Common Issues

### Calendar renders as grey box
The `table_calendar` widget uses `locale: 'pt_BR'`. If `initializeDateFormatting('pt_BR', null)` is not called in `main()` before `runApp()`, the calendar crashes with `LocaleDataException`. Check `lib/main.dart` for the initialization call.

### Admin login fails
Admin users are created by registering normally then running `UPDATE users SET is_admin = TRUE` via SQL. The password is whatever was used during registration — double-check with curl before testing in the browser.

## Security Audit Checklist

1. **JWT_SECRET** — Check `backend/internal/auth/jwt.go` for hardcoded fallback. In production, the app should fail if `JWT_SECRET` env var is not set.
2. **CORS** — Check `backend/cmd/api/main.go` for `AllowedOrigins: ["*"]` with `AllowCredentials: true`. Should be restricted in production.
3. **Database exposure** — Check `docker-compose.yml` for `ports: "5432:5432"`. DB port should not be exposed externally in production.
4. **Rate limiting** — Check if `/api/auth/login` and `/api/auth/register` have rate limiting middleware. Missing rate limiting enables brute force attacks.
5. **Password hashing** — Verify bcrypt is used (check `auth_handler.go` for `bcrypt.GenerateFromPassword`).
6. **password_hash in responses** — Verify no API endpoint returns the password hash field.
7. **SQL injection** — Verify all queries use parameterized statements (`$1`, `$2`, etc.).

## Devin Secrets Needed
- `GH_ANDRESNSN_PAT` — GitHub PAT for pushing code and creating PRs
