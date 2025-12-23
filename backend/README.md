# DevJourney Backend

Unified NestJS backend for DevJourney platform, combining API, Runner, and AI services.

## Features

- 🔐 **Authentication** - JWT-based auth with Passport
- 📝 **Challenges API** - CRUD operations for coding challenges
- ⚡ **Code Execution** - Secure Docker-based code runner with BullMQ
- 🤖 **AI Integration** - OpenAI-powered hints and code analysis
- 📊 **PostgreSQL** - Prisma ORM for database operations
- 🚀 **Redis & BullMQ** - Async job queue for code execution
- 📚 **Swagger** - Auto-generated API documentation

## Architecture

```
backend/
├── src/
│   ├── main.ts                 # Application entry point
│   ├── app.module.ts           # Root module
│   ├── api/                    # REST API endpoints
│   │   ├── auth/               # Authentication
│   │   ├── challenges/         # Challenge management
│   │   ├── submissions/        # Code submissions
│   │   └── users/              # User management
│   ├── runner/                 # Code execution engine
│   │   ├── runner.service.ts   # Docker-based execution
│   │   └── execution.processor.ts  # BullMQ worker
│   ├── ai/                     # AI-powered features
│   │   ├── ai.service.ts       # OpenAI integration
│   │   └── ai.controller.ts    # AI endpoints
│   └── prisma/                 # Database service
└── prisma/
    └── schema.prisma           # Database schema
```

## Prerequisites

- Node.js ≥18.17.0
- pnpm ≥8.15.0
- PostgreSQL 14+
- Redis 7+
- Docker (for code execution)

## Installation

```bash
# Install dependencies
pnpm install

# Generate Prisma client
pnpm prisma:generate

# Run migrations
pnpm prisma:migrate
```

## Configuration

Create `.env` file:

```env
# Server
PORT=3001
NODE_ENV=development
ALLOWED_ORIGINS=http://localhost:3000

# Database
DATABASE_URL="postgresql://devjourney:devjourney_pass@localhost:5432/devjourney"

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=7d

# AI (OpenAI)
AI_API_KEY=your-openai-api-key
AI_MODEL=gpt-4-turbo-preview

# Docker
DOCKER_HOST=/var/run/docker.sock
```

## Development

```bash
# Start development server with watch mode
pnpm start:dev

# Run Prisma Studio (database GUI)
pnpm prisma:studio
```

## Production

```bash
# Build application
pnpm build

# Start production server
pnpm start:prod
```

## API Documentation

Once the server is running, visit:
- Swagger UI: http://localhost:3001/api/docs

## Testing

```bash
# Unit tests
pnpm test

# E2E tests
pnpm test:e2e

# Test coverage
pnpm test:cov
```

## Modules

### API Module
REST API endpoints for:
- Authentication (register, login, JWT)
- Challenges (list, get by ID, filter by difficulty/tags)
- Submissions (submit code, get status, view history)
- Users (profile management)

### Runner Module
Code execution engine using:
- Docker containers (isolated environments)
- BullMQ job queue (async processing)
- Multi-language support (JavaScript, Python, Java, C++)
- Resource limits (time, memory)

### AI Module
AI-powered features:
- Hint generation (context-aware coding hints)
- Code analysis (quality, bugs, performance)
- OpenAI GPT-4 integration

## Database Schema

Key entities:
- `User` - User accounts
- `Challenge` - Coding challenges
- `TestCase` - Test cases for challenges
- `Submission` - User code submissions
- `UserProgress` - Learning progress tracking

## Security

- Helmet middleware (HTTP headers)
- CORS configuration
- JWT authentication
- Rate limiting (Throttler)
- Input validation (class-validator)
- Docker isolation for code execution

## Performance

- Compression middleware
- Connection pooling (Prisma)
- Redis caching
- BullMQ job queue
- Docker container reuse
