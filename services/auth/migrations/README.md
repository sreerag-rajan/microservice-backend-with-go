# Auth Service Database Migrations

This directory contains database migration scripts for the Auth Service, which manages user identity, authentication, and session management.

## Migration Files

### 001_create_schemas.sql
- Creates the `sr_auth` schema
- This is the foundation schema for all Auth Service tables

### 002_create_users_table.sql
- Creates the main `users` table in the `sr_auth` schema
- Contains core user identity information (email, phone, password_hash, etc.)
- Includes performance indexes and auto-update triggers
- This table is shared with the User Service (read-only access for User Service)

### 003_add_is_verified_to_users.sql
- Adds `is_verified` column to the users table
- Tracks email/phone verification status
- Includes index for verification status queries

### 004_create_otp_tokens_table.sql
- Creates OTP tokens table for managing one-time passwords
- Supports various use cases: email verification, phone verification, password reset, 2FA
- Includes expiration tracking and usage status

### 005_create_sessions_table.sql
- Creates sessions table for managing user login sessions
- Stores refresh token hashes and device information
- Tracks session expiration and revocation

### 006_create_login_logs_table.sql
- Creates login logs table for security audit trail
- Tracks login attempts, successes, failures, and security events
- Supports security monitoring and threat detection

### 007_create_devices_table.sql
- Creates devices table for managing user devices
- Tracks device trust status and device-specific settings
- Supports device fingerprinting and 2FA bypass for trusted devices

### 008_create_providers_table.sql
- Creates OAuth providers table for managing OAuth integrations
- Stores provider configurations (Google, Microsoft, GitHub, etc.)
- Manages client credentials and OAuth endpoints

### 009_create_user_providers_table.sql
- Creates user_providers table for OAuth provider relationships
- Manages user OAuth accounts and tokens
- Supports multiple providers per user with primary designation

### 010_add_oauth_fields_to_users.sql
- Adds OAuth-related fields to users table
- Tracks authentication method (password, oauth, both)
- Links users to their primary OAuth provider

## Table Structure

### users Table
```sql
CREATE TABLE sr_auth.users (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false, -- Email/phone verification status
    auth_method sr_auth.auth_method DEFAULT 'password', -- 'password', 'oauth', 'both'
    primary_provider_id INTEGER REFERENCES sr_auth.providers(id), -- Primary OAuth provider
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);
```

### otp_tokens Table
```sql
CREATE TABLE sr_auth.otp_tokens (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES sr_auth.users(id) ON DELETE CASCADE,
    otp_code VARCHAR(10) NOT NULL,
    use_case VARCHAR(50) NOT NULL, -- 'email_verification', 'phone_verification', 'password_reset', 'two_factor'
    is_used BOOLEAN DEFAULT false,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ DEFAULT NULL,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### sessions Table
```sql
CREATE TABLE sr_auth.sessions (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES sr_auth.users(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL,
    device_info JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ NOT NULL,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ DEFAULT NULL,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### login_logs Table
```sql
CREATE TABLE sr_auth.login_logs (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    user_id INTEGER REFERENCES sr_auth.users(id) ON DELETE SET NULL,
    session_id INTEGER REFERENCES sr_auth.sessions(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL, -- 'login_success', 'login_failed', 'logout', 'session_expired', 'password_changed', 'account_locked'
    ip_address INET,
    user_agent TEXT,
    device_info JSONB DEFAULT '{}',
    success BOOLEAN NOT NULL,
    failure_reason VARCHAR(255),
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### devices Table
```sql
CREATE TABLE sr_auth.devices (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES sr_auth.users(id) ON DELETE CASCADE,
    device_name VARCHAR(255),
    device_type VARCHAR(50), -- 'mobile', 'desktop', 'tablet', 'unknown'
    device_id VARCHAR(255), -- Unique device identifier (fingerprint)
    browser VARCHAR(100),
    os VARCHAR(100),
    ip_address INET,
    is_trusted BOOLEAN DEFAULT false, -- Whether this device is trusted (skip 2FA)
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    trusted_at TIMESTAMPTZ DEFAULT NULL,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### providers Table
```sql
CREATE TABLE sr_auth.providers (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL, -- 'google', 'microsoft', 'github', 'facebook', 'apple', 'linkedin'
    display_name VARCHAR(255) NOT NULL, -- 'Google', 'Microsoft', 'GitHub', 'Facebook', 'Apple', 'LinkedIn'
    client_id VARCHAR(255) NOT NULL,
    client_secret VARCHAR(500) NOT NULL, -- Encrypted client secret
    authorization_url TEXT NOT NULL,
    token_url TEXT NOT NULL,
    userinfo_url TEXT,
    scopes TEXT, -- Space-separated scopes
    redirect_uri TEXT,
    is_active BOOLEAN DEFAULT true,
    is_enabled BOOLEAN DEFAULT false, -- Whether this provider is enabled for use
    config JSONB DEFAULT '{}', -- Provider-specific configuration
    meta JSONB DEFAULT '{}', -- Additional metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### user_providers Table
```sql
CREATE TABLE sr_auth.user_providers (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES sr_auth.users(id) ON DELETE CASCADE,
    provider_id INTEGER NOT NULL REFERENCES sr_auth.providers(id) ON DELETE CASCADE,
    provider_user_id VARCHAR(255) NOT NULL, -- The user ID from the OAuth provider
    access_token TEXT, -- Encrypted access token
    refresh_token TEXT, -- Encrypted refresh token
    token_type VARCHAR(50), -- 'Bearer', 'MAC', etc.
    expires_at TIMESTAMPTZ, -- Token expiration time
    profile_data JSONB DEFAULT '{}', -- User profile data from provider
    is_primary BOOLEAN DEFAULT false, -- Whether this is the primary login method
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    meta JSONB DEFAULT '{}', -- Additional metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Running Migrations

### Prerequisites
- PostgreSQL database
- Database user with CREATE SCHEMA and CREATE TABLE permissions

### Manual Execution
```bash
# Connect to your PostgreSQL database
psql -h localhost -U your_user -d your_database

# Run migrations in order
\i 001_create_schemas.sql
\i 002_create_users_table.sql
\i 003_add_is_verified_to_users.sql
\i 004_create_otp_tokens_table.sql
\i 005_create_sessions_table.sql
\i 006_create_login_logs_table.sql
\i 007_create_devices_table.sql
\i 008_create_providers_table.sql
\i 009_create_user_providers_table.sql
\i 010_add_oauth_fields_to_users.sql
```

### Using a Migration Tool
If you're using a migration tool like golang-migrate, you can run:
```bash
migrate -path ./services/auth/migrations -database "postgres://user:password@localhost/dbname?sslmode=disable" up
```

## Rollback
To rollback migrations, uncomment the DOWN migration sections in each file and run them in reverse order:
```bash
# Rollback in reverse order
\i 010_add_oauth_fields_to_users.sql  # Uncomment DOWN section
\i 009_create_user_providers_table.sql  # Uncomment DOWN section
\i 008_create_providers_table.sql  # Uncomment DOWN section
\i 007_create_devices_table.sql  # Uncomment DOWN section
\i 006_create_login_logs_table.sql  # Uncomment DOWN section
\i 005_create_sessions_table.sql  # Uncomment DOWN section
\i 004_create_otp_tokens_table.sql  # Uncomment DOWN section
\i 003_add_is_verified_to_users.sql  # Uncomment DOWN section
\i 002_create_users_table.sql  # Uncomment DOWN section
\i 001_create_schemas.sql  # Uncomment DOWN section
```

## Prerequisites

**IMPORTANT**: Global migrations must be run before Auth Service migrations:

```bash
# 1. Run global migrations first
cd ../../migrations
psql -h localhost -U your_user -d your_database -f 001_install_extensions.sql
psql -h localhost -U your_user -d your_database -f 002_create_utility_functions.sql
psql -h localhost -U your_user -d your_database -f 003_create_common_indexes.sql

# 2. Then run Auth Service migrations
cd ../services/auth/migrations
psql -h localhost -U your_user -d your_database -f 001_create_schemas.sql
psql -h localhost -U your_user -d your_database -f 002_create_users_table.sql
psql -h localhost -U your_user -d your_database -f 003_add_is_verified_to_users.sql
psql -h localhost -U your_user -d your_database -f 004_create_otp_tokens_table.sql
psql -h localhost -U your_user -d your_database -f 005_create_sessions_table.sql
psql -h localhost -U your_user -d your_database -f 006_create_login_logs_table.sql
psql -h localhost -U your_user -d your_database -f 007_create_devices_table.sql
psql -h localhost -U your_user -d your_database -f 008_create_providers_table.sql
psql -h localhost -U your_user -d your_database -f 009_create_user_providers_table.sql
psql -h localhost -U your_user -d your_database -f 010_add_oauth_fields_to_users.sql
```

## Key Features

### OTP Management
- **Multiple Use Cases**: Email verification, phone verification, password reset, 2FA
- **Expiration Tracking**: Automatic expiration of OTP codes
- **Usage Tracking**: Prevents reuse of OTP codes
- **Security**: OTP codes are stored with metadata for audit trail

### Session Management
- **Refresh Token Security**: Refresh tokens are hashed for security
- **Device Tracking**: Stores device information and IP addresses
- **Session Revocation**: Support for manual session revocation
- **Expiration**: Automatic session expiration

### Security Audit Trail
- **Comprehensive Logging**: All authentication events are logged
- **Security Monitoring**: Failed login attempts and suspicious activities
- **Device Tracking**: Device fingerprinting and trust management
- **IP Tracking**: IP address tracking for security analysis

### Device Management
- **Device Fingerprinting**: Unique device identification
- **Trust Management**: Trusted devices can skip 2FA
- **Device History**: Track device usage and activity
- **Security Controls**: Device-specific security settings

### OAuth Integration
- **Multiple Providers**: Google, Microsoft, GitHub, Facebook, Apple, LinkedIn
- **Provider Management**: Configurable OAuth provider settings
- **Multiple Accounts**: Users can link multiple OAuth accounts
- **Token Management**: Secure storage and refresh of OAuth tokens
- **Profile Data**: Cache user profile information from providers
- **Primary Provider**: Designate primary authentication method

## Notes

- The `users` table is shared with the User Service
- User Service has read-only access to this table
- All tables implement soft delete using the `deleted_at` column where applicable
- Automatic `updated_at` timestamps are handled by triggers from global migrations
- Performance indexes are created for common query patterns
- Utility functions are provided by global migrations
- OTP codes have configurable expiration times
- Sessions support multiple concurrent logins per user
- Login logs provide comprehensive security audit trail
- Device management supports modern security practices
