-- Migration: 005_create_sessions_table
-- Description: Create sessions table for managing user login sessions and refresh tokens
-- Created: 2024-01-01

-- UP Migration
CREATE TABLE sr_auth.sessions (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES sr_auth.users(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL, -- Hashed refresh token for security
    device_info JSONB DEFAULT '{}', -- Device information (browser, OS, device type, etc.)
    ip_address INET,
    user_agent TEXT,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ NOT NULL,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ DEFAULT NULL,
    meta JSONB DEFAULT '{}', -- Additional session metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_sessions_user_id ON sr_auth.sessions(user_id);
CREATE INDEX idx_sessions_refresh_token_hash ON sr_auth.sessions(refresh_token_hash);
CREATE INDEX idx_sessions_active ON sr_auth.sessions(is_active) WHERE is_active = true;
CREATE INDEX idx_sessions_expires_at ON sr_auth.sessions(expires_at);
CREATE INDEX idx_sessions_last_used_at ON sr_auth.sessions(last_used_at);
CREATE INDEX idx_sessions_created_at ON sr_auth.sessions(created_at);

-- Create trigger for auto-updating updated_at
CREATE TRIGGER update_sessions_updated_at 
    BEFORE UPDATE ON sr_auth.sessions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- DOWN Migration
-- DROP TRIGGER IF EXISTS update_sessions_updated_at ON sr_auth.sessions;
-- DROP TABLE IF EXISTS sr_auth.sessions;
