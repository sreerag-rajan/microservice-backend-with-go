-- Migration: 010_add_oauth_fields_to_users
-- Description: Add OAuth-related fields to users table for authentication method tracking
-- Created: 2024-01-01

-- UP Migration

-- Create enum for authentication methods
CREATE TYPE sr_auth.auth_method AS ENUM ('password', 'oauth', 'both');

-- Add OAuth fields to users table
ALTER TABLE sr_auth.users 
ADD COLUMN auth_method sr_auth.auth_method DEFAULT 'password',
ADD COLUMN primary_provider_id INTEGER REFERENCES sr_auth.providers(id) ON DELETE SET NULL;

-- Create indexes for OAuth fields
CREATE INDEX idx_users_auth_method ON sr_auth.users(auth_method);
CREATE INDEX idx_users_primary_provider ON sr_auth.users(primary_provider_id);

-- DOWN Migration
-- DROP INDEX IF EXISTS idx_users_primary_provider;
-- DROP INDEX IF EXISTS idx_users_auth_method;
-- ALTER TABLE sr_auth.users DROP COLUMN IF EXISTS primary_provider_id;
-- ALTER TABLE sr_auth.users DROP COLUMN IF EXISTS auth_method;
-- DROP TYPE IF EXISTS sr_auth.auth_method;
