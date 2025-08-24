-- Migration: 003_add_is_verified_to_users
-- Description: Add is_verified column to users table for email/phone verification status
-- Created: 2024-01-01

-- UP Migration
ALTER TABLE sr_auth.users 
ADD COLUMN is_verified BOOLEAN DEFAULT false;

-- Create index for verification status
CREATE INDEX idx_users_verified ON sr_auth.users(is_verified) WHERE is_verified = true;

-- DOWN Migration
-- DROP INDEX IF EXISTS idx_users_verified;
-- ALTER TABLE sr_auth.users DROP COLUMN IF EXISTS is_verified;
