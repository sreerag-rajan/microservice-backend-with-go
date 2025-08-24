# Shared Packages (pkgs)

This directory contains reusable packages and utilities that are shared across different layers of the microservices architecture. These packages follow the DRY (Don't Repeat Yourself) principle and provide common functionality.

## Package Structure

```
pkgs/
├── jwt/                    # JWT token utilities
│   ├── jwt.go             # JWT manager implementation
│   ├── jwt_test.go        # JWT tests
│   └── README.md          # JWT package documentation
├── go.mod                 # Go module file
└── README.md              # This file
```

## Available Packages

### JWT Package (`jwt/`)

Provides JWT (JSON Web Token) utilities for authentication and authorization across services.

**Features:**
- Generate access and refresh tokens
- Validate tokens and extract claims
- Token refresh functionality
- Type-safe token validation
- Expiration management

**Usage:**
```go
import "github.com/your-project/pkgs/jwt"

jwtManager := jwt.NewJWTManager(
    os.Getenv("JWT_SECRET"),
    15*time.Minute,  // Access token expiry
    7*24*time.Hour,  // Refresh token expiry
)

// Generate tokens
accessToken, refreshToken, err := jwtManager.GenerateTokenPair("user123", "user@example.com")
```

## Design Principles

### 1. Reusability
- Packages are designed to be used across multiple services
- Minimal dependencies to avoid conflicts
- Clear interfaces and abstractions

### 2. Independence
- No circular dependencies between packages
- Each package can be used independently
- No assumptions about usage context

### 3. Backward Compatibility
- Maintain API stability across versions
- Use semantic versioning for breaking changes
- Comprehensive test coverage

### 4. Performance
- Optimized for common use cases
- Minimal memory allocations
- Efficient algorithms

## Adding New Packages

When adding new packages to this directory:

1. **Create a new directory** for the package
2. **Add comprehensive documentation** in README.md
3. **Include unit tests** for all functionality
4. **Follow Go naming conventions**
5. **Keep dependencies minimal**
6. **Update this README** with package information

### Package Template

```
package-name/
├── package.go          # Main package implementation
├── package_test.go     # Unit tests
├── README.md           # Package documentation
└── examples/           # Usage examples (optional)
```

## Dependencies

This directory uses minimal external dependencies to ensure compatibility across services:

- `github.com/golang-jwt/jwt/v5`: JWT implementation

## Testing

Run tests for all packages:

```bash
cd pkgs
go test ./...
```

Run tests for a specific package:

```bash
cd pkgs/jwt
go test -v
```

## Integration

Packages in this directory are designed to be imported by:

- **Service Layer**: Core business services
- **Application Layer**: Client-facing services
- **Gateway Layer**: API gateway (if needed)

### Import Example

```go
import (
    "github.com/your-project/pkgs/jwt"
    // Add other packages as needed
)
```

## Versioning

Packages follow semantic versioning (SemVer):
- **Major**: Breaking changes
- **Minor**: New features (backward compatible)
- **Patch**: Bug fixes (backward compatible)

## Contributing

When contributing to shared packages:

1. **Follow Go best practices**
2. **Add comprehensive tests**
3. **Update documentation**
4. **Consider backward compatibility**
5. **Test integration with existing services**

## Architecture Compliance

These packages follow the microservices architecture rules:

- **No business logic**: Only utilities and helpers
- **No application state**: Stateless operations only
- **Minimal dependencies**: Reduce coupling between services
- **Clear interfaces**: Easy to use and understand
