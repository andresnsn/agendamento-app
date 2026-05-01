# Agendamento App

App de agendamento com **Flutter** (iOS, Android, Web) e **Backend Go**.

## Funcionalidades

### Cliente
- Login com e-mail/senha, Google, Apple ou celular
- Cadastro com nome
- Visualização de calendário com dias disponíveis
- Seleção de horários disponíveis por dia
- Confirmação de agendamento
- Listagem e cancelamento de agendamentos

### Administrador
- Painel com visão macro dos agendamentos
- Visualização de todos os clientes agendados
- Adição e exclusão de agendamentos
- Gerenciamento de horários disponíveis por dia
- Notificações por e-mail e SMS ao receber novos agendamentos

## Stack

- **Frontend**: Flutter 3.x + Material 3 (tema rosa)
- **Backend**: Go 1.22 + gorilla/mux
- **Banco de dados**: PostgreSQL 16
- **Autenticação**: JWT (Firebase Auth planejado para login social)
- **Notificações**: SMTP (e-mail) + Twilio (SMS)
- **Containerização**: Docker + Docker Compose

## Rodando com Docker

```bash
docker compose up --build
```

O app estará disponível em:
- **Frontend (Web)**: http://localhost
- **Backend API**: http://localhost:8080
- **PostgreSQL**: localhost:5432

## Rodando localmente (desenvolvimento)

### Backend

```bash
cd backend
# Ter PostgreSQL rodando localmente
export DB_HOST=localhost DB_PORT=5432 DB_USER=postgres DB_PASSWORD=postgres DB_NAME=agendamento
go run ./cmd/api
```

### Frontend

```bash
flutter pub get
flutter run -d chrome  # Web
flutter run             # Mobile (com emulador)
```

## Variáveis de Ambiente

| Variável | Descrição | Padrão |
|---|---|---|
| `DB_HOST` | Host do PostgreSQL | `localhost` |
| `DB_PORT` | Porta do PostgreSQL | `5432` |
| `DB_USER` | Usuário do PostgreSQL | `postgres` |
| `DB_PASSWORD` | Senha do PostgreSQL | `postgres` |
| `DB_NAME` | Nome do banco | `agendamento` |
| `JWT_SECRET` | Secret para tokens JWT | (dev default) |
| `PORT` | Porta do backend | `8080` |
| `ADMIN_EMAIL` | E-mail do admin para notificações | - |
| `ADMIN_PHONE` | Celular do admin para SMS | - |
| `SMTP_HOST` | Host SMTP | `smtp.gmail.com` |
| `SMTP_PORT` | Porta SMTP | `587` |
| `SMTP_USER` | Usuário SMTP | - |
| `SMTP_PASS` | Senha SMTP | - |

## API Endpoints

### Públicos
- `POST /api/auth/login` — Login
- `POST /api/auth/register` — Cadastro
- `POST /api/auth/social` — Login social

### Autenticados
- `GET /api/slots?date=YYYY-MM-DD` — Listar horários
- `POST /api/appointments` — Criar agendamento
- `GET /api/appointments/me` — Meus agendamentos
- `DELETE /api/appointments/:id` — Cancelar agendamento

### Admin
- `GET /api/admin/appointments` — Todos os agendamentos
- `POST /api/admin/appointments` — Criar agendamento (admin)
- `DELETE /api/admin/appointments/:id` — Excluir agendamento
- `POST /api/admin/slots` — Criar horário
- `DELETE /api/admin/slots/:id` — Excluir horário
- `GET /api/admin/users` — Listar usuários

## Estrutura

```
├── lib/                  # Flutter app
│   ├── main.dart
│   ├── theme/            # Tema Material 3 rosa
│   ├── models/           # Modelos de dados
│   ├── providers/        # State management (Provider)
│   ├── screens/          # Telas (login, calendário, admin)
│   ├── services/         # API service
│   └── widgets/          # Widgets reutilizáveis
├── backend/              # Go API
│   ├── cmd/api/          # Entry point
│   └── internal/
│       ├── auth/         # JWT + middlewares
│       ├── database/     # PostgreSQL + migrações
│       ├── handlers/     # HTTP handlers
│       ├── models/       # Modelos Go
│       └── notifications/ # E-mail + SMS
├── docker-compose.yml    # Orquestração
├── Dockerfile            # Flutter Web (nginx)
└── backend/Dockerfile    # Go API
```
