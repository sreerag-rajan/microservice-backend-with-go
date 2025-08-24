# Auth Service Database Schema

This document provides a comprehensive overview of the Auth Service database schema, including all tables, relationships, and key features.

## Schema Overview

The Auth Service uses the `sr_auth` schema and consists of 7 main tables:

1. **users** - Core user identity and authentication data
2. **otp_tokens** - One-time password management
3. **sessions** - User session and refresh token management
4. **login_logs** - Security audit trail and login tracking
5. **devices** - Device management and trust status
6. **providers** - OAuth provider configurations
7. **user_providers** - User OAuth provider relationships

## Table Relationships

```
users (1) ──── (N) otp_tokens
  │
  ├── (1) ──── (N) sessions
  │
  ├── (1) ──── (N) login_logs
  │
  ├── (1) ──── (N) devices
  │
  ├── (1) ──── (N) user_providers
  │
  └── (1) ──── (1) providers (via primary_provider_id)

providers (1) ──── (N) user_providers
```

## Detailed Table Schemas

### 1. users Table
**Purpose**: Core user identity and authentication data
**Shared**: Yes (read-only access for User Service)

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL PRIMARY KEY | Auto-incrementing primary key |
| `uuid` | UUID UNIQUE | Globally unique identifier |
| `email` | VARCHAR(255) UNIQUE | User email address |
| `phone` | VARCHAR(20) UNIQUE | User phone number |
| `password_hash` | VARCHAR(255) | Bcrypt hashed password |
| `is_active` | BOOLEAN | Account active status |
| `is_verified` | BOOLEAN | Email/phone verification status |
| `auth_method` | sr_auth.auth_method | Authentication method ('password', 'oauth', 'both') |
| `primary_provider_id` | INTEGER | Primary OAuth provider reference |
| `meta` | JSONB | Additional user metadata |
| `created_at` | TIMESTAMPTZ | Account creation timestamp |
| `updated_at` | TIMESTAMPTZ | Last update timestamp |
| `deleted_at` | TIMESTAMPTZ | Soft delete timestamp |

**Key Indexes**:
- `idx_users_uuid` - UUID lookups
- `idx_users_email` - Email lookups
- `idx_users_phone` - Phone lookups
- `idx_users_verified` - Verification status queries
- `idx_users_auth_method` - Authentication method queries
- `idx_users_primary_provider` - Primary provider lookups

### 2. otp_tokens Table
**Purpose**: One-time password management for various use cases

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL PRIMARY KEY | Auto-incrementing primary key |
| `uuid` | UUID UNIQUE | Globally unique identifier |
| `user_id` | INTEGER | Foreign key to users table |
| `otp_code` | VARCHAR(10) | Generated OTP code |
| `use_case` | VARCHAR(50) | OTP purpose (email_verification, phone_verification, password_reset, two_factor) |
| `is_used` | BOOLEAN | Whether OTP has been consumed |
| `expires_at` | TIMESTAMPTZ | OTP expiration timestamp |
| `used_at` | TIMESTAMPTZ | When OTP was used |
| `meta` | JSONB | Additional OTP metadata |
| `created_at` | TIMESTAMPTZ | OTP creation timestamp |
| `updated_at` | TIMESTAMPTZ | Last update timestamp |

**Key Indexes**:
- `idx_otp_tokens_user_id` - User-specific OTP queries
- `idx_otp_tokens_unused` - Unused OTP queries
- `idx_otp_tokens_expires_at` - Expiration queries

### 3. sessions Table
**Purpose**: User session and refresh token management

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL PRIMARY KEY | Auto-incrementing primary key |
| `uuid` | UUID UNIQUE | Globally unique identifier |
| `user_id` | INTEGER | Foreign key to users table |
| `refresh_token_hash` | VARCHAR(255) | Hashed refresh token |
| `device_info` | JSONB | Device information (browser, OS, etc.) |
| `ip_address` | INET | Session IP address |
| `user_agent` | TEXT | User agent string |
| `is_active` | BOOLEAN | Session active status |
| `expires_at` | TIMESTAMPTZ | Session expiration timestamp |
| `last_used_at` | TIMESTAMPTZ | Last session usage |
| `revoked_at` | TIMESTAMPTZ | Session revocation timestamp |
| `meta` | JSONB | Additional session metadata |
| `created_at` | TIMESTAMPTZ | Session creation timestamp |
| `updated_at` | TIMESTAMPTZ | Last update timestamp |

**Key Indexes**:
- `idx_sessions_user_id` - User session queries
- `idx_sessions_refresh_token_hash` - Token validation
- `idx_sessions_active` - Active session queries

### 4. login_logs Table
**Purpose**: Security audit trail and login tracking

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL PRIMARY KEY | Auto-incrementing primary key |
| `uuid` | UUID UNIQUE | Globally unique identifier |
| `user_id` | INTEGER | Foreign key to users table (NULL for failed attempts) |
| `session_id` | INTEGER | Foreign key to sessions table |
| `event_type` | VARCHAR(50) | Event type (login_success, login_failed, logout, etc.) |
| `ip_address` | INET | Event IP address |
| `user_agent` | TEXT | User agent string |
| `device_info` | JSONB | Device information |
| `success` | BOOLEAN | Whether event was successful |
| `failure_reason` | VARCHAR(255) | Reason for failure |
| `meta` | JSONB | Additional event metadata |
| `created_at` | TIMESTAMPTZ | Event timestamp |

**Key Indexes**:
- `idx_login_logs_user_id` - User event history
- `idx_login_logs_event_type` - Event type queries
- `idx_login_logs_success` - Success/failure analysis
- `idx_login_logs_user_events` - User event timeline

### 5. devices Table
**Purpose**: Device management and trust status

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL PRIMARY KEY | Auto-incrementing primary key |
| `uuid` | UUID UNIQUE | Globally unique identifier |
| `user_id` | INTEGER | Foreign key to users table |
| `device_name` | VARCHAR(255) | User-friendly device name |
| `device_type` | VARCHAR(50) | Device type (mobile, desktop, tablet) |
| `device_id` | VARCHAR(255) | Unique device fingerprint |
| `browser` | VARCHAR(100) | Browser information |
| `os` | VARCHAR(100) | Operating system |
| `ip_address` | INET | Device IP address |
| `is_trusted` | BOOLEAN | Whether device is trusted (skip 2FA) |
| `is_active` | BOOLEAN | Device active status |
| `last_used_at` | TIMESTAMPTZ | Last device usage |
| `trusted_at` | TIMESTAMPTZ | When device was trusted |
| `meta` | JSONB | Additional device metadata |
| `created_at` | TIMESTAMPTZ | Device registration timestamp |
| `updated_at` | TIMESTAMPTZ | Last update timestamp |

**Key Indexes**:
- `idx_devices_user_id` - User device queries
- `idx_devices_device_id` - Device fingerprint lookups
- `idx_devices_trusted` - Trusted device queries
- `idx_devices_user_device` - Unique user-device constraint

### 6. providers Table
**Purpose**: OAuth provider configurations and settings

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL PRIMARY KEY | Auto-incrementing primary key |
| `uuid` | UUID UNIQUE | Globally unique identifier |
| `name` | VARCHAR(100) UNIQUE | Provider name (google, microsoft, github, etc.) |
| `display_name` | VARCHAR(255) | Human-readable provider name |
| `client_id` | VARCHAR(255) | OAuth client ID |
| `client_secret` | VARCHAR(500) | Encrypted OAuth client secret |
| `authorization_url` | TEXT | OAuth authorization endpoint |
| `token_url` | TEXT | OAuth token endpoint |
| `userinfo_url` | TEXT | User info endpoint |
| `scopes` | TEXT | Required OAuth scopes |
| `redirect_uri` | TEXT | OAuth redirect URI |
| `is_active` | BOOLEAN | Provider active status |
| `is_enabled` | BOOLEAN | Whether provider is enabled for use |
| `config` | JSONB | Provider-specific configuration |
| `meta` | JSONB | Additional provider metadata |
| `created_at` | TIMESTAMPTZ | Provider creation timestamp |
| `updated_at` | TIMESTAMPTZ | Last update timestamp |

**Key Indexes**:
- `idx_providers_name` - Provider name lookups
- `idx_providers_active` - Active provider queries
- `idx_providers_enabled` - Enabled provider queries

### 7. user_providers Table
**Purpose**: User OAuth provider relationships and token management

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL PRIMARY KEY | Auto-incrementing primary key |
| `uuid` | UUID UNIQUE | Globally unique identifier |
| `user_id` | INTEGER | Foreign key to users table |
| `provider_id` | INTEGER | Foreign key to providers table |
| `provider_user_id` | VARCHAR(255) | User ID from OAuth provider |
| `access_token` | TEXT | Encrypted OAuth access token |
| `refresh_token` | TEXT | Encrypted OAuth refresh token |
| `token_type` | VARCHAR(50) | Token type (Bearer, MAC, etc.) |
| `expires_at` | TIMESTAMPTZ | Token expiration timestamp |
| `profile_data` | JSONB | User profile data from provider |
| `is_primary` | BOOLEAN | Whether this is the primary login method |
| `is_active` | BOOLEAN | Provider relationship active status |
| `last_used_at` | TIMESTAMPTZ | Last provider usage timestamp |
| `meta` | JSONB | Additional relationship metadata |
| `created_at` | TIMESTAMPTZ | Relationship creation timestamp |
| `updated_at` | TIMESTAMPTZ | Last update timestamp |

**Key Indexes**:
- `idx_user_providers_user_id` - User provider queries
- `idx_user_providers_provider_id` - Provider-specific queries
- `idx_user_providers_provider_user_id` - Provider user ID lookups
- `idx_user_providers_primary` - Primary provider queries
- `idx_user_providers_user_provider` - Unique user-provider constraint

## Key Features

### 🔐 Security Features
- **Password Security**: Bcrypt hashed passwords
- **Token Security**: Refresh tokens are hashed
- **OTP Security**: Time-based expiration and usage tracking
- **Session Security**: Automatic expiration and revocation
- **Device Security**: Device fingerprinting and trust management

### 📊 Audit & Monitoring
- **Comprehensive Logging**: All authentication events logged
- **Security Monitoring**: Failed attempts and suspicious activities
- **Device Tracking**: Device usage and trust status
- **IP Tracking**: IP address monitoring for security

### 🔄 Session Management
- **Multiple Sessions**: Support for concurrent logins
- **Session Revocation**: Manual session termination
- **Device Tracking**: Device-specific session information
- **Automatic Expiration**: Configurable session timeouts

### 📱 Device Management
- **Device Fingerprinting**: Unique device identification
- **Trust Management**: Trusted devices can skip 2FA
- **Device History**: Track device usage patterns
- **Security Controls**: Device-specific security settings

### 🔢 OTP System
- **Multiple Use Cases**: Email/phone verification, password reset, 2FA
- **Expiration Management**: Automatic OTP expiration
- **Usage Tracking**: Prevent OTP reuse
- **Security Metadata**: Store OTP context information

### 🔗 OAuth Integration
- **Multiple Providers**: Google, Microsoft, GitHub, Facebook, Apple, LinkedIn
- **Provider Management**: Configurable OAuth provider settings
- **Multiple Accounts**: Users can link multiple OAuth accounts
- **Token Management**: Secure storage and refresh of OAuth tokens
- **Profile Data**: Cache user profile information from providers
- **Primary Provider**: Designate primary authentication method

## Data Flow Examples

### User Registration Flow
1. Create user record in `users` table
2. Generate OTP in `otp_tokens` table
3. Send OTP via notification service
4. User verifies OTP (updates `otp_tokens.is_used`)
5. Update `users.is_verified` to true

### User Login Flow
1. Validate credentials against `users` table
2. Create session record in `sessions` table
3. Log successful login in `login_logs` table
4. Update device information in `devices` table
5. Return access and refresh tokens

### Session Management Flow
1. Validate refresh token against `sessions` table
2. Check session expiration and active status
3. Update `last_used_at` timestamp
4. Generate new access token
5. Log token refresh in `login_logs` table

### OAuth Login Flow
1. User initiates OAuth login with provider
2. Redirect to provider's authorization URL
3. User authorizes application
4. Exchange authorization code for tokens
5. Fetch user profile from provider
6. Create/update user record in `users` table
7. Create/update `user_providers` record
8. Create session record in `sessions` table
9. Log successful OAuth login in `login_logs` table
10. Return access and refresh tokens

### OAuth Token Refresh Flow
1. Validate refresh token from `user_providers` table
2. Check token expiration and active status
3. Exchange refresh token for new access token
4. Update `user_providers` record with new tokens
5. Update `last_used_at` timestamp
6. Log token refresh in `login_logs` table

## Performance Considerations

### Indexing Strategy
- **Primary Keys**: All tables use SERIAL primary keys
- **UUID Indexes**: UUID columns indexed for lookups
- **Foreign Keys**: User ID indexes for relationship queries
- **Composite Indexes**: Multi-column indexes for complex queries
- **Partial Indexes**: Filtered indexes for active records

### Query Optimization
- **Soft Deletes**: Only users table implements soft delete
- **JSONB Usage**: Metadata stored in JSONB for flexibility
- **Timestamp Indexes**: Created/updated timestamps indexed
- **Status Indexes**: Active/verified status indexes

## Security Best Practices

### Data Protection
- **Password Hashing**: Bcrypt with appropriate cost
- **Token Hashing**: Refresh tokens hashed in database
- **IP Tracking**: IP addresses stored for security analysis
- **Device Fingerprinting**: Unique device identification

### Access Control
- **Session Management**: Automatic session expiration
- **Device Trust**: Trusted device management
- **Audit Trail**: Comprehensive event logging
- **Rate Limiting**: OTP and login attempt tracking

### Privacy Compliance
- **Data Minimization**: Only necessary data stored
- **Retention Policies**: Configurable data retention
- **Audit Logging**: Complete audit trail
- **Data Encryption**: Sensitive data encrypted at rest
