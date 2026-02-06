# Paisa Khai Backend

A simple REST API backend for the Paisa Khai personal finance tracker app.

## Tech Stack

- **Runtime**: Bun
- **Framework**: Express.js
- **Database**: PostgreSQL
- **ORM**: Drizzle ORM
- **Authentication**: JWT with refresh tokens
- **Language**: TypeScript

## Getting Started

### 1. Install Dependencies

```bash
bun install
```

### 2. Set Up Environment Variables

Copy the example env file and update with your values:

```bash
cp .env.example .env
```

Edit `.env` and set:
- `DATABASE_URL`: Your PostgreSQL connection string
- `JWT_ACCESS_SECRET`: A random secret for access tokens
- `JWT_REFRESH_SECRET`: A random secret for refresh tokens

### 3. Set Up Database

First, create a PostgreSQL database called `paisa_khai`.

Then generate and run migrations:

```bash
# Generate migration files from schema
bun run db:generate

# Run migrations to create tables
bun run db:migrate
```

Or use push (for development):

```bash
bun run db:push
```

### 4. Start the Server

Development (with auto-reload):

```bash
bun run dev
```

Production:

```bash
bun run start
```

The server will start at `http://localhost:3000`

## API Endpoints

### Authentication

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/auth/register` | Register new user | No |
| POST | `/api/auth/login` | Login | No |
| POST | `/api/auth/refresh` | Refresh access token | No |
| POST | `/api/auth/logout` | Logout | Yes |
| GET | `/api/auth/me` | Get current user | Yes |

### Categories

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/categories` | Get all categories | Yes |
| GET | `/api/categories/:id` | Get single category | Yes |
| POST | `/api/categories` | Create category | Yes |
| PUT | `/api/categories/:id` | Update category | Yes |
| DELETE | `/api/categories/:id` | Delete category | Yes |

### Sources (Money Sources)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/sources` | Get all sources | Yes |
| GET | `/api/sources/:id` | Get single source | Yes |
| POST | `/api/sources` | Create source | Yes |
| PUT | `/api/sources/:id` | Update source | Yes |
| DELETE | `/api/sources/:id` | Delete source | Yes |

### Transactions

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/transactions` | Get all transactions | Yes |
| GET | `/api/transactions/:id` | Get single transaction | Yes |
| POST | `/api/transactions` | Create transaction | Yes |
| PUT | `/api/transactions/:id` | Update transaction | Yes |
| DELETE | `/api/transactions/:id` | Delete transaction | Yes |
| GET | `/api/transactions/stats/summary` | Get summary stats | Yes |

## Request/Response Examples

### Register

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe"
  }'
```

Response:
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "John Doe"
    },
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc..."
  }
}
```

### Create Transaction

```bash
curl -X POST http://localhost:3000/api/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "title": "Grocery Shopping",
    "amount": 50.00,
    "date": "2024-01-15T10:00:00Z",
    "type": "expense",
    "category": "Food",
    "description": "Weekly groceries",
    "sources": [
       { "sourceId": "source-uuid", "amount": 50.00 }
    ]
  }'
```

### Authentication Flow

1. **Register** or **Login** to get `accessToken` and `refreshToken`
2. Use `accessToken` in Authorization header: `Bearer <accessToken>`
3. When `accessToken` expires (15 min), use `/api/auth/refresh` with your `refreshToken`
4. Get new tokens and continue

## Database Schema

```
users
├── id (uuid, primary key)
├── email (unique)
├── password (hashed)
├── name
├── created_at
└── updated_at

categories
├── id (uuid, primary key)
├── user_id (foreign key → users)
├── name
├── type (income/expense/both)
├── icon (emoji)
├── color (hex)
├── budget (optional)
├── created_at
└── updated_at

sources
├── id (uuid, primary key)
├── user_id (foreign key → users)
├── name
├── type (bank/wallet/cash)
├── icon
├── color
├── initial_balance
├── created_at
└── updated_at

transactions
├── id (uuid, primary key)
├── user_id (foreign key → users)
├── title
├── amount
├── date
├── type (income/expense)
├── category
├── description (optional)
├── related_person (optional)
├── is_urgent
├── receipt_path (optional)
├── created_at
└── updated_at

transaction_source_splits
├── id (uuid, primary key)
├── transaction_id (foreign key → transactions)
├── source_id (foreign key → sources)
└── amount

refresh_tokens
├── id (uuid, primary key)
├── user_id (foreign key → users)
├── token
├── expires_at
└── created_at
```

## Scripts

```bash
bun run dev          # Start dev server with watch mode
bun run start        # Start production server
bun run db:generate  # Generate migrations from schema
bun run db:migrate   # Run migrations
bun run db:push      # Push schema directly (dev only)
bun run db:studio    # Open Drizzle Studio (database GUI)
```

## Project Structure

```
backend/
├── src/
│   ├── db/
│   │   ├── index.ts      # Database connection
│   │   ├── migrate.ts    # Migration script
│   │   └── schema.ts     # Database schema
│   ├── middleware/
│   │   └── auth.ts       # JWT auth middleware
│   ├── routes/
│   │   ├── auth.ts       # Auth endpoints
│   │   ├── categories.ts # Category CRUD
│   │   ├── sources.ts    # Source CRUD
│   │   └── transactions.ts # Transaction CRUD
│   ├── utils/
│   │   └── jwt.ts        # JWT helpers
│   └── index.ts          # Main entry point
├── drizzle/              # Generated migrations
├── .env.example
├── drizzle.config.ts
├── package.json
├── tsconfig.json
└── README.md
```
