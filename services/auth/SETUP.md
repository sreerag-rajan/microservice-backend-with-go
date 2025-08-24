# Auth Service Setup

## Environment Variables

Create a `.env` file in the auth service root directory with the following variables:

```env
# Auth Service Configuration
PORT=50051
DB_CONNECTION_URL=postgres://username:password@localhost:5432/auth_db?sslmode=disable
MAX_CONNECTION_POOL=10
```

### Environment Variables Explained

- `PORT`: The port on which the gRPC server will listen (default: 50051)
- `DB_CONNECTION_URL`: PostgreSQL connection string
- `MAX_CONNECTION_POOL`: Maximum number of database connections in the pool (default: 10)

## Running the Service

1. Install dependencies:
   ```bash
   go mod tidy
   ```

2. Set up your environment variables in a `.env` file

3. Run the service:
   ```bash
   go run cmd/main.go
   ```

   Or use the Makefile:
   ```bash
   make run
   ```

## Building the Service

To build the service:
```bash
make build
```

This will create a binary in the `bin/` directory.

## Testing

The auth service uses a dedicated `tests/` folder for all test files, organized by layer:

### Run all tests:
```bash
make test
```

### Run all tests (including internal tests):
```bash
make test-all
```

### Test Structure:
```
tests/
├── config_test.go         # Configuration layer tests
├── repository_test.go     # Repository layer tests
├── business_test.go       # Business logic layer tests
├── handlers_test.go       # gRPC handlers tests
└── helpers_test.go        # Common test utilities
```

See `tests/README.md` for detailed testing documentation.

## Database Connection

The service uses PostgreSQL with connection pooling configured as follows:
- Max Open Connections: Set by `MAX_CONNECTION_POOL`
- Max Idle Connections: Half of max open connections
- Connection Lifetime: 1 hour

## Architecture

The auth service follows the microservices architecture pattern:

- **cmd/main.go**: Entry point and server initialization
- **internal/config**: Configuration management and database connection
- **internal/repository**: Database access layer
- **internal/business**: Business logic layer
- **internal/handlers**: gRPC service handlers

## Next Steps

1. Implement the gRPC protocol definitions in `proto/` directory
2. Add authentication business logic in the business layer
3. Implement database operations in the repository layer
4. Add proper error handling and logging
5. Implement authentication methods (register, login, validate token, etc.)
