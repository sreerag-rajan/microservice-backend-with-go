# Auth Service Tests

This directory contains all tests for the auth service, organized by layer and functionality.

## Test Structure

```
tests/
├── README.md              # This file
├── config_test.go         # Configuration layer tests
├── repository_test.go     # Repository layer tests
├── business_test.go       # Business logic layer tests
├── handlers_test.go       # gRPC handlers tests
└── helpers_test.go        # Common test utilities and helpers
```

## Running Tests

### Run all tests in the tests folder:
```bash
make test
```

### Run all tests (including any internal tests):
```bash
make test-all
```

### Run specific test files:
```bash
go test ./tests/config_test.go
go test ./tests/repository_test.go
```

## Test Organization

### 1. **config_test.go**
Tests for the configuration layer:
- Environment variable loading
- Configuration validation
- Database connection configuration

### 2. **repository_test.go**
Tests for the repository layer:
- Database operations
- Data access patterns
- Repository initialization

### 3. **business_test.go**
Tests for the business logic layer:
- Authentication workflows
- Business rule validation
- Service orchestration

### 4. **handlers_test.go**
Tests for the gRPC handlers:
- Request/response handling
- gRPC service methods
- Error handling

### 5. **helpers_test.go**
Common test utilities:
- Test environment setup
- Mock database connections
- Test cleanup utilities

## Test Utilities

### TestSetup
The `TestSetup` struct provides a complete test environment with all layers initialized:

```go
setup := SetupTestEnvironment(t)
defer CleanupTestEnvironment(t, setup)

// Use setup.Config, setup.DB, setup.Repo, etc.
```

### Environment Variables
Tests automatically set up required environment variables:
- `DB_CONNECTION_URL`: Test database connection
- `PORT`: Test port (50051)
- `MAX_CONNECTION_POOL`: Test connection pool size (5)

## Adding New Tests

When adding new tests:

1. **Create test files** in the appropriate layer
2. **Use the test helpers** for common setup
3. **Follow naming conventions**: `TestFunctionName`
4. **Add cleanup** for any resources created
5. **Update this README** if adding new test categories

## Test Best Practices

- Use descriptive test names
- Test both success and failure cases
- Mock external dependencies
- Clean up resources after tests
- Use table-driven tests for multiple scenarios
- Keep tests independent and isolated

## Integration Tests

For integration tests that require a real database:

1. Set up a test database
2. Use the `SetupTestEnvironment` helper
3. Run tests with `make test-all`
4. Ensure proper cleanup in `CleanupTestEnvironment`

## Mocking Strategy

- **Database**: Use `MockDB()` for unit tests
- **External Services**: Create mock implementations
- **Configuration**: Use test environment variables
- **gRPC**: Use gRPC testing utilities
