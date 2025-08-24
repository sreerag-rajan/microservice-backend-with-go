# AUTH Service

## Introduction

The Auth Service is a core microservice responsible for user authentication and authorization. It provides secure user management, token generation, and OTP-based verification capabilities. This service follows the gRPC architecture pattern and integrates with the notification system for OTP delivery.

## Core Functionality

### User Management
- **Create User**: Register new users with email, phone, and password
- **Update User**: Modify user profile information
- **Update Password**: Change user passwords securely

### Authentication & Authorization
- **Generate Access Token**: Create JWT access tokens for authenticated users
- **Generate Refresh Token**: Create refresh tokens for token renewal
- **Refresh Access Token**: Renew access tokens using valid refresh tokens

### OTP (One-Time Password) System
- **Generate OTP**: Create time-based OTPs for various use cases:
  - User verification (email/phone)
  - Password reset
  - Two-factor authentication
- **Validate OTP**: Verify OTP codes and mark them as used

## Database Structure

### Users Table
Stores core user information:
- `id`: Unique user identifier
- `email`: User email address (unique)
- `phone`: User phone number (unique)
- `password_hash`: Securely hashed password
- `is_verified`: Email/phone verification status
- `created_at`: Account creation timestamp
- `updated_at`: Last update timestamp

### Sessions Table
Tracks user login sessions:
- `id`: Session identifier
- `user_id`: Reference to user
- `refresh_token`: Encrypted refresh token
- `expires_at`: Token expiration timestamp
- `created_at`: Session creation timestamp

### OTP Tokens Table
Manages OTP generation and validation:
- `id`: Token identifier
- `user_id`: Reference to user
- `otp_code`: Generated OTP code
- `use_case`: Purpose of OTP (verification, password_reset, etc.)
- `is_used`: Whether OTP has been consumed
- `expires_at`: OTP expiration timestamp
- `created_at`: Token creation timestamp

## gRPC API Endpoints

### User Management
```protobuf
service AuthService {
  // Create new user account
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
  
  // Update user profile information
  rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse);
  
  // Update user password
  rpc UpdatePassword(UpdatePasswordRequest) returns (UpdatePasswordResponse);
}
```

### Authentication
```protobuf
service AuthService {
  // Generate access and refresh tokens
  rpc GenerateTokens(GenerateTokensRequest) returns (GenerateTokensResponse);
  
  // Refresh access token using refresh token
  rpc RefreshAccessToken(RefreshTokenRequest) returns (RefreshTokenResponse);
}
```

### OTP Management
```protobuf
service AuthService {
  // Generate OTP for various use cases
  rpc GenerateOTP(GenerateOTPRequest) returns (GenerateOTPResponse);
  
  // Validate OTP code
  rpc ValidateOTP(ValidateOTPRequest) returns (ValidateOTPResponse);
}
```

## Integration Points

### Notification Service
- Publishes OTP generation events to RabbitMQ
- Notification service consumes events and sends OTP via email/SMS

### Message Queue Events
```json
{
  "event_type": "otp_generated",
  "user_id": "uuid",
  "email": "user@example.com",
  "phone": "+1234567890",
  "otp_code": "123456",
  "use_case": "email_verification",
  "expires_at": "2024-01-01T12:00:00Z"
}
```

## Configuration

### Environment Variables
```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=auth_service
DB_USER=auth_user
DB_PASSWORD=auth_password

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_ACCESS_TOKEN_EXPIRY=15m
JWT_REFRESH_TOKEN_EXPIRY=7d

# Service
SERVICE_PORT=50051
SERVICE_NAME=auth-service

# RabbitMQ
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
RABBITMQ_EXCHANGE=auth_events

# Redis (for caching)
REDIS_URL=redis://localhost:6379
```

## Security Features

- **Password Hashing**: Uses bcrypt for secure password storage
- **JWT Tokens**: Secure token-based authentication
- **OTP Expiration**: Time-based OTP expiration for security
- **Rate Limiting**: Prevents brute force attacks
- **Input Validation**: Comprehensive request validation

## Development

### Prerequisites
- Go 1.21+
- PostgreSQL 14+
- Redis 6+
- RabbitMQ 3.8+

### Running Locally
```bash
# Install dependencies
go mod tidy

# Run migrations
make migrate

# Start service
make run
```

### Testing
```bash
# Run all tests
make test

# Run specific test
go test ./internal/business -v
```

## Architecture Compliance

This service follows the microservices architecture rules:
- **Service Layer**: Core business logic with direct database access
- **gRPC Communication**: Provides gRPC services to Application Layer
- **Event Publishing**: Publishes events to RabbitMQ for async processing
- **No HTTP Endpoints**: Only gRPC communication as per architecture
- **Database Access**: Direct PostgreSQL connections for data operations
