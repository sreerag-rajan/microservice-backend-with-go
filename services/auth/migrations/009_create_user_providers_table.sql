-- Migration: 009_create_user_providers_table
-- Description: Create user_providers table for managing user OAuth provider relationships
-- Created: 2024-01-01

-- UP Migration
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

-- Create indexes for performance
CREATE INDEX idx_user_providers_user_id ON sr_auth.user_providers(user_id);
CREATE INDEX idx_user_providers_provider_id ON sr_auth.user_providers(provider_id);
CREATE INDEX idx_user_providers_provider_user_id ON sr_auth.user_providers(provider_id, provider_user_id);
CREATE INDEX idx_user_providers_primary ON sr_auth.user_providers(user_id, is_primary) WHERE is_primary = true;
CREATE INDEX idx_user_providers_active ON sr_auth.user_providers(is_active) WHERE is_active = true;
CREATE INDEX idx_user_providers_last_used_at ON sr_auth.user_providers(last_used_at);
CREATE INDEX idx_user_providers_created_at ON sr_auth.user_providers(created_at);

-- Create unique constraint for user-provider combination
CREATE UNIQUE INDEX idx_user_providers_user_provider ON sr_auth.user_providers(user_id, provider_id);

-- Create trigger for auto-updating updated_at
CREATE TRIGGER update_user_providers_updated_at 
    BEFORE UPDATE ON sr_auth.user_providers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- DOWN Migration
-- DROP TRIGGER IF EXISTS update_user_providers_updated_at ON sr_auth.user_providers;
-- DROP TABLE IF EXISTS sr_auth.user_providers;
