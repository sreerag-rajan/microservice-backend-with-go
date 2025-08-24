# JWT Package

This package provides generic JWT (JSON Web Token) utilities for token generation, validation, and management across the microservices architecture. It is completely service-agnostic and can be used for any JWT purpose.

## Features

- **Generic Token Generation**: Generate JWT tokens with any claims structure
- **Token Parsing**: Parse and validate tokens with custom claims
- **Flexible Claims**: Support for any claims that implement jwt.Claims interface
- **Expiration Management**: Check token expiration status
- **Service Agnostic**: No hardcoded service-specific logic

## Usage

### Initialization

```go
import "github.com/your-project/pkgs/jwt"

// Create JWT manager with secret key
jwtManager := jwt.NewJWTManager("your-secret-key")
```

### Creating Custom Claims

```go
// Define your own claims structure
type AuthClaims struct {
    jwt.BaseClaims  // Embed BaseClaims for standard JWT fields
    UserID string   `json:"user_id"`
    Email  string   `json:"email"`
    Type   string   `json:"type"`
}

// Implement CustomClaims interface for expiry setting
func (a *AuthClaims) SetExpiry(expiry time.Duration) {
    a.BaseClaims.SetExpiry(expiry)
}
```

### Generate Tokens

```go
// Create claims
claims := &AuthClaims{
    UserID: "user123",
    Email:  "user@example.com",
    Type:   "access",
}
claims.SetExpiry(15 * time.Minute)
claims.SetIssuer("auth-service")
claims.SetSubject("user123")

// Generate token
token, err := jwtManager.GenerateToken(claims)

// Or generate with custom expiry
token, err := jwtManager.GenerateTokenWithExpiry(claims, 7*24*time.Hour)
```

### Parse and Validate Tokens

```go
// Parse token
parsedClaims := &AuthClaims{}
err := jwtManager.ParseToken(tokenString, parsedClaims)

// Check if token is expired
isExpired, err := jwtManager.IsTokenExpired(tokenString, &AuthClaims{})

// Get token expiration time
expiration, err := jwtManager.GetTokenExpiration(tokenString, &AuthClaims{})
```

### Parse Without Validation

```go
// Parse token without validating expiry (useful for extracting info from expired tokens)
parsedClaims := &AuthClaims{}
err := jwtManager.ParseTokenWithoutValidation(tokenString, parsedClaims)
```

## BaseClaims

The package provides `BaseClaims` which implements the standard JWT claims interface:

```go
type BaseClaims struct {
    ExpiresAt *jwt.NumericDate `json:"exp,omitempty"`
    IssuedAt  *jwt.NumericDate `json:"iat,omitempty"`
    NotBefore *jwt.NumericDate `json:"nbf,omitempty"`
    Issuer    string           `json:"iss,omitempty"`
    Subject   string           `json:"sub,omitempty"`
    Audience  jwt.ClaimStrings `json:"aud,omitempty"`
    ID        string           `json:"jti,omitempty"`
}
```

### BaseClaims Methods

```go
claims := &BaseClaims{}

// Set standard JWT fields
claims.SetExpiry(15 * time.Minute)
claims.SetIssuedAt(time.Now())
claims.SetNotBefore(time.Now())
claims.SetIssuer("your-service")
claims.SetSubject("user123")
claims.SetAudience([]string{"api"})
claims.SetID("token-123")

// Get standard JWT fields
expTime, _ := claims.GetExpirationTime()
issuer, _ := claims.GetIssuer()
subject, _ := claims.GetSubject()
```

## Service Integration Examples

### Auth Service Example

```go
// In auth service
type AuthClaims struct {
    jwt.BaseClaims
    UserID string `json:"user_id"`
    Email  string `json:"email"`
    Type   string `json:"type"` // "access" or "refresh"
}

func (a *AuthClaims) SetExpiry(expiry time.Duration) {
    a.BaseClaims.SetExpiry(expiry)
}

// Generate access token
accessClaims := &AuthClaims{
    UserID: userID,
    Email:  email,
    Type:   "access",
}
accessClaims.SetExpiry(15 * time.Minute)
accessClaims.SetIssuer("auth-service")

accessToken, err := jwtManager.GenerateToken(accessClaims)
```

### Other Service Example

```go
// In notification service
type NotificationClaims struct {
    jwt.BaseClaims
    NotificationID string `json:"notification_id"`
    RecipientID    string `json:"recipient_id"`
    Priority       string `json:"priority"`
}

func (n *NotificationClaims) SetExpiry(expiry time.Duration) {
    n.BaseClaims.SetExpiry(expiry)
}

// Generate notification token
notifClaims := &NotificationClaims{
    NotificationID: "notif-123",
    RecipientID:    "user-456",
    Priority:       "high",
}
notifClaims.SetExpiry(1 * time.Hour)

notifToken, err := jwtManager.GenerateToken(notifClaims)
```

## Environment Configuration

```env
JWT_SECRET=your-super-secret-jwt-key
```

## Error Handling

The package returns descriptive errors for various scenarios:

- `failed to parse token`: Token format is invalid
- `invalid token`: Token signature is invalid
- `unexpected signing method`: Wrong signing algorithm
- `token has no expiration time`: Token doesn't have expiry field

## Design Principles

- **Service Agnostic**: No hardcoded service names or logic
- **Flexible Claims**: Support any claims structure
- **Reusable**: Can be used across all services
- **Type Safe**: Leverages Go's type system
- **Minimal Dependencies**: Only depends on jwt/v5

## Dependencies

- `github.com/golang-jwt/jwt/v5`: JWT implementation
