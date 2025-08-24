-- Migration: 001_create_auth_schema
-- Description: Complete Auth Service schema creation with all tables, indexes, and initial data
-- Created: 2024-01-01
-- Dependencies: Global migrations (001_install_extensions.sql, 002_create_utility_functions.sql, 003_create_common_indexes.sql)

-- UP Migration

-- Start transaction
BEGIN;

-- Create schema
CREATE SCHEMA IF NOT EXISTS sr_auth;

-- Create enum for authentication methods
CREATE TYPE sr_auth.auth_method AS ENUM ('password', 'oauth', 'both');

-- Create users table with all required fields
CREATE TABLE sr_auth.users (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT generate_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    auth_method sr_auth.auth_method DEFAULT 'password',
    primary_provider_id INTEGER, -- Will be set as FK after providers table is created
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    updated_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Create OTP tokens table
CREATE TABLE sr_auth.otp_tokens (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT generate_uuid(),
    user_id INTEGER NOT NULL REFERENCES sr_auth.users(id) ON DELETE CASCADE,
    otp_code VARCHAR(10) NOT NULL,
    use_case VARCHAR(50) NOT NULL, -- 'email_verification', 'phone_verification', 'password_reset', 'two_factor'
    is_used BOOLEAN DEFAULT false,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ DEFAULT NULL,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    updated_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Create sessions table
CREATE TABLE sr_auth.sessions (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT generate_uuid(),
    user_id INTEGER NOT NULL REFERENCES sr_auth.users(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL,
    device_info JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ NOT NULL,
    last_used_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    revoked_at TIMESTAMPTZ DEFAULT NULL,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    updated_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Create login logs table
CREATE TABLE sr_auth.login_logs (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT generate_uuid(),
    user_id INTEGER REFERENCES sr_auth.users(id) ON DELETE SET NULL,
    session_id INTEGER REFERENCES sr_auth.sessions(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL, -- 'login_success', 'login_failed', 'logout', 'session_expired', 'password_changed', 'account_locked'
    ip_address INET,
    user_agent TEXT,
    device_info JSONB DEFAULT '{}',
    success BOOLEAN NOT NULL,
    failure_reason VARCHAR(255),
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    updated_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Create devices table
CREATE TABLE sr_auth.devices (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT generate_uuid(),
    user_id INTEGER NOT NULL REFERENCES sr_auth.users(id) ON DELETE CASCADE,
    device_name VARCHAR(255),
    device_type VARCHAR(50), -- 'mobile', 'desktop', 'tablet', 'unknown'
    device_id VARCHAR(255),
    browser VARCHAR(100),
    os VARCHAR(100),
    ip_address INET,
    is_trusted BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    trusted_at TIMESTAMPTZ DEFAULT NULL,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    updated_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Create providers table
CREATE TABLE sr_auth.providers (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT generate_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL, -- 'google', 'microsoft', 'github', 'facebook', 'apple', 'linkedin'
    display_name VARCHAR(255) NOT NULL,
    client_id VARCHAR(255) NOT NULL,
    client_secret VARCHAR(500) NOT NULL,
    authorization_url TEXT NOT NULL,
    token_url TEXT NOT NULL,
    userinfo_url TEXT,
    scopes TEXT,
    redirect_uri TEXT,
    is_active BOOLEAN DEFAULT true,
    is_enabled BOOLEAN DEFAULT false,
    config JSONB DEFAULT '{}',
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    updated_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Create user_providers table
CREATE TABLE sr_auth.user_providers (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT generate_uuid(),
    user_id INTEGER NOT NULL REFERENCES sr_auth.users(id) ON DELETE CASCADE,
    provider_id INTEGER NOT NULL REFERENCES sr_auth.providers(id) ON DELETE CASCADE,
    provider_user_id VARCHAR(255) NOT NULL,
    access_token TEXT,
    refresh_token TEXT,
    token_type VARCHAR(50),
    expires_at TIMESTAMPTZ,
    profile_data JSONB DEFAULT '{}',
    is_primary BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    updated_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Add foreign key constraint for users.primary_provider_id
ALTER TABLE sr_auth.users 
ADD CONSTRAINT fk_users_primary_provider 
FOREIGN KEY (primary_provider_id) REFERENCES sr_auth.providers(id) ON DELETE SET NULL;

-- Add common indexes using global utility functions (for tables with is_active column)
SELECT add_common_indexes('sr_auth', 'users');
SELECT add_common_indexes('sr_auth', 'sessions');
SELECT add_common_indexes('sr_auth', 'devices');
SELECT add_common_indexes('sr_auth', 'providers');
SELECT add_common_indexes('sr_auth', 'user_providers');

-- Add common indexes manually for tables without is_active column
-- OTP tokens table (no is_active column)
CREATE INDEX IF NOT EXISTS idx_otp_tokens_uuid ON sr_auth.otp_tokens(uuid);
CREATE INDEX IF NOT EXISTS idx_otp_tokens_created_at ON sr_auth.otp_tokens(created_at);
CREATE INDEX IF NOT EXISTS idx_otp_tokens_updated_at ON sr_auth.otp_tokens(updated_at);
CREATE INDEX IF NOT EXISTS idx_otp_tokens_deleted_at ON sr_auth.otp_tokens(deleted_at) WHERE deleted_at IS NULL;

-- Login logs table (no is_active column)
CREATE INDEX IF NOT EXISTS idx_login_logs_uuid ON sr_auth.login_logs(uuid);
CREATE INDEX IF NOT EXISTS idx_login_logs_created_at ON sr_auth.login_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_login_logs_updated_at ON sr_auth.login_logs(updated_at);
CREATE INDEX IF NOT EXISTS idx_login_logs_deleted_at ON sr_auth.login_logs(deleted_at) WHERE deleted_at IS NULL;

-- Add service-specific indexes
CREATE INDEX idx_users_email ON sr_auth.users(email);
CREATE INDEX idx_users_phone ON sr_auth.users(phone);
CREATE INDEX idx_users_active ON sr_auth.users(is_active) WHERE is_active = true;
CREATE INDEX idx_users_verified ON sr_auth.users(is_verified) WHERE is_verified = true;
CREATE INDEX idx_users_auth_method ON sr_auth.users(auth_method);
CREATE INDEX idx_users_primary_provider ON sr_auth.users(primary_provider_id);

CREATE INDEX idx_otp_tokens_user_id ON sr_auth.otp_tokens(user_id);
CREATE INDEX idx_otp_tokens_otp_code ON sr_auth.otp_tokens(otp_code);
CREATE INDEX idx_otp_tokens_use_case ON sr_auth.otp_tokens(use_case);
CREATE INDEX idx_otp_tokens_expires_at ON sr_auth.otp_tokens(expires_at);
CREATE INDEX idx_otp_tokens_unused ON sr_auth.otp_tokens(user_id, use_case, is_used) WHERE is_used = false;

CREATE INDEX idx_sessions_user_id ON sr_auth.sessions(user_id);
CREATE INDEX idx_sessions_refresh_token_hash ON sr_auth.sessions(refresh_token_hash);
CREATE INDEX idx_sessions_active ON sr_auth.sessions(is_active) WHERE is_active = true;
CREATE INDEX idx_sessions_expires_at ON sr_auth.sessions(expires_at);
CREATE INDEX idx_sessions_last_used_at ON sr_auth.sessions(last_used_at);

CREATE INDEX idx_login_logs_user_id ON sr_auth.login_logs(user_id);
CREATE INDEX idx_login_logs_session_id ON sr_auth.login_logs(session_id);
CREATE INDEX idx_login_logs_event_type ON sr_auth.login_logs(event_type);
CREATE INDEX idx_login_logs_success ON sr_auth.login_logs(success);
CREATE INDEX idx_login_logs_ip_address ON sr_auth.login_logs(ip_address);
CREATE INDEX idx_login_logs_user_events ON sr_auth.login_logs(user_id, event_type, created_at);

CREATE INDEX idx_devices_user_id ON sr_auth.devices(user_id);
CREATE INDEX idx_devices_device_id ON sr_auth.devices(device_id);
CREATE INDEX idx_devices_trusted ON sr_auth.devices(is_trusted) WHERE is_trusted = true;
CREATE INDEX idx_devices_active ON sr_auth.devices(is_active) WHERE is_active = true;
CREATE INDEX idx_devices_last_used_at ON sr_auth.devices(last_used_at);
CREATE UNIQUE INDEX idx_devices_user_device ON sr_auth.devices(user_id, device_id) WHERE device_id IS NOT NULL;

CREATE INDEX idx_providers_name ON sr_auth.providers(name);
CREATE INDEX idx_providers_active ON sr_auth.providers(is_active) WHERE is_active = true;
CREATE INDEX idx_providers_enabled ON sr_auth.providers(is_enabled) WHERE is_enabled = true;

CREATE INDEX idx_user_providers_user_id ON sr_auth.user_providers(user_id);
CREATE INDEX idx_user_providers_provider_id ON sr_auth.user_providers(provider_id);
CREATE INDEX idx_user_providers_provider_user_id ON sr_auth.user_providers(provider_id, provider_user_id);
CREATE INDEX idx_user_providers_primary ON sr_auth.user_providers(user_id, is_primary) WHERE is_primary = true;
CREATE INDEX idx_user_providers_active ON sr_auth.user_providers(is_active) WHERE is_active = true;
CREATE INDEX idx_user_providers_last_used_at ON sr_auth.user_providers(last_used_at);
CREATE UNIQUE INDEX idx_user_providers_user_provider ON sr_auth.user_providers(user_id, provider_id);

-- Create triggers for auto-updating updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON sr_auth.users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_otp_tokens_updated_at 
    BEFORE UPDATE ON sr_auth.otp_tokens 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sessions_updated_at 
    BEFORE UPDATE ON sr_auth.sessions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_login_logs_updated_at 
    BEFORE UPDATE ON sr_auth.login_logs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_devices_updated_at 
    BEFORE UPDATE ON sr_auth.devices 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_providers_updated_at 
    BEFORE UPDATE ON sr_auth.providers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_providers_updated_at 
    BEFORE UPDATE ON sr_auth.user_providers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert common OAuth providers
INSERT INTO sr_auth.providers (name, display_name, client_id, client_secret, authorization_url, token_url, userinfo_url, scopes, is_enabled) VALUES
('google', 'Google', '', '', 'https://accounts.google.com/o/oauth2/v2/auth', 'https://oauth2.googleapis.com/token', 'https://www.googleapis.com/oauth2/v2/userinfo', 'openid email profile', false),
('microsoft', 'Microsoft', '', '', 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize', 'https://login.microsoftonline.com/common/oauth2/v2.0/token', 'https://graph.microsoft.com/v1.0/me', 'openid email profile', false),
('github', 'GitHub', '', '', 'https://github.com/login/oauth/authorize', 'https://github.com/login/oauth/access_token', 'https://api.github.com/user', 'read:user user:email', false),
('facebook', 'Facebook', '', '', 'https://www.facebook.com/v12.0/dialog/oauth', 'https://graph.facebook.com/v12.0/oauth/access_token', 'https://graph.facebook.com/v12.0/me', 'email public_profile', false),
('apple', 'Apple', '', '', 'https://appleid.apple.com/auth/authorize', 'https://appleid.apple.com/auth/token', '', 'name email', false),
('linkedin', 'LinkedIn', '', '', 'https://www.linkedin.com/oauth/v2/authorization', 'https://www.linkedin.com/oauth/v2/accessToken', 'https://api.linkedin.com/v2/me', 'r_liteprofile r_emailaddress', false);

-- Commit transaction
COMMIT;

-- DOWN Migration
-- DROP TRIGGER IF EXISTS update_user_providers_updated_at ON sr_auth.user_providers;
-- DROP TRIGGER IF EXISTS update_providers_updated_at ON sr_auth.providers;
-- DROP TRIGGER IF EXISTS update_devices_updated_at ON sr_auth.devices;
-- DROP TRIGGER IF EXISTS update_login_logs_updated_at ON sr_auth.login_logs;
-- DROP TRIGGER IF EXISTS update_sessions_updated_at ON sr_auth.sessions;
-- DROP TRIGGER IF EXISTS update_otp_tokens_updated_at ON sr_auth.otp_tokens;
-- DROP TRIGGER IF EXISTS update_users_updated_at ON sr_auth.users;
-- DROP TABLE IF EXISTS sr_auth.user_providers;
-- DROP TABLE IF EXISTS sr_auth.providers;
-- DROP TABLE IF EXISTS sr_auth.devices;
-- DROP TABLE IF EXISTS sr_auth.login_logs;
-- DROP TABLE IF EXISTS sr_auth.sessions;
-- DROP TABLE IF EXISTS sr_auth.otp_tokens;
-- DROP TABLE IF EXISTS sr_auth.users;
-- DROP TYPE IF EXISTS sr_auth.auth_method;
-- DROP SCHEMA IF EXISTS sr_auth CASCADE;
