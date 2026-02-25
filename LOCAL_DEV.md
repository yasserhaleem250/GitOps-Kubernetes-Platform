# Local Development Setup

Quick setup for local development and testing.

## Prerequisites

- Docker and Docker Compose
- Node.js 18+ (for direct npm commands)
- npm or yarn

## Running Locally with Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Remove volumes
docker-compose down -v
```

## Accessing Services

- **Frontend**: http://localhost:3001
- **Backend API**: http://localhost:3000

## Testing Backend API

```bash
# Get users
curl http://localhost:3000/api/v1/users

# Get service info
curl http://localhost:3000/api/v1/info

# Create user
curl -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Health check
curl http://localhost:3000/health

# Readiness check
curl http://localhost:3000/readiness
```

## Running Without Docker

### Backend

```bash
cd backend

# Install dependencies
npm install

# Start development server
npm start

# Server will run on http://localhost:3000
```

### Frontend

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm start

# App will open on http://localhost:3000 (or next available port)
```

## Building Docker Images

```bash
# Build backend image
docker build -t backend:latest backend/

# Build frontend image
docker build -t frontend:latest frontend/

# Test images locally
docker run -p 3000:3000 backend:latest
docker run -p 3001:3000 frontend:latest
```

## Useful Commands

```bash
# View Docker Compose logs
docker-compose logs

# Tail specific service logs
docker-compose logs -f backend

# Restart services
docker-compose restart

# Rebuild services
docker-compose up -d --build

# Run commands in container
docker-compose exec backend npm test

# Remove all containers and volumes
docker-compose down -v
```

## Environment Variables

### Backend

- `NODE_ENV`: Development/production mode
- `PORT`: Server port (default: 3000)

### Frontend

- `REACT_APP_API_URL`: Backend API URL (default: http://localhost:3000)

## Development Notes

- Frontend uses Create React App with hot reload
- Backend uses Node.js with Express
- Both services are health-checked
- Services are on the same Docker network for inter-service communication
- Volumes are mounted for live code updates during development
