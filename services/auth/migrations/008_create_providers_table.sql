-- Migration: 008_create_providers_table
-- Description: Create providers table for OAuth provider configurations
-- Created: 2024-01-01

-- UP Migration
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

-- Create indexes for performance
CREATE INDEX idx_providers_name ON sr_auth.providers(name);
CREATE INDEX idx_providers_active ON sr_auth.providers(is_active) WHERE is_active = true;
CREATE INDEX idx_providers_enabled ON sr_auth.providers(is_enabled) WHERE is_enabled = true;
CREATE INDEX idx_providers_created_at ON sr_auth.providers(created_at);

-- Create trigger for auto-updating updated_at
CREATE TRIGGER update_providers_updated_at 
    BEFORE UPDATE ON sr_auth.providers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert common OAuth providers
INSERT INTO sr_auth.providers (name, display_name, client_id, client_secret, authorization_url, token_url, userinfo_url, scopes, is_enabled) VALUES
('google', 'Google', '', '', 'https://accounts.google.com/o/oauth2/v2/auth', 'https://oauth2.googleapis.com/token', 'https://www.googleapis.com/oauth2/v2/userinfo', 'openid email profile', false),
('microsoft', 'Microsoft', '', '', 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize', 'https://login.microsoftonline.com/common/oauth2/v2.0/token', 'https://graph.microsoft.com/v1.0/me', 'openid email profile', false),
('github', 'GitHub', '', '', 'https://github.com/login/oauth/authorize', 'https://github.com/login/oauth/access_token', 'https://api.github.com/user', 'read:user user:email', false),
('facebook', 'Facebook', '', '', 'https://www.facebook.com/v12.0/dialog/oauth', 'https://graph.facebook.com/v12.0/oauth/access_token', 'https://graph.facebook.com/v12.0/me', 'email public_profile', false),
('apple', 'Apple', '', '', 'https://appleid.apple.com/auth/authorize', 'https://appleid.apple.com/auth/token', '', 'name email', false),
('linkedin', 'LinkedIn', '', '', 'https://www.linkedin.com/oauth/v2/authorization', 'https://www.linkedin.com/oauth/v2/accessToken', 'https://api.linkedin.com/v2/me', 'r_liteprofile r_emailaddress', false);

-- DOWN Migration
-- DROP TRIGGER IF EXISTS update_providers_updated_at ON sr_auth.providers;
-- DROP TABLE IF EXISTS sr_auth.providers;
