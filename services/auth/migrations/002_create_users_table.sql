-- Migration: 003_create_users_table
-- Description: Create users table in sr_auth schema with all required fields and indexes
-- Created: 2024-01-01

-- UP Migration
CREATE TABLE sr_auth.users (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Create indexes for performance
CREATE INDEX idx_users_uuid ON sr_auth.users(uuid);
CREATE INDEX idx_users_email ON sr_auth.users(email);
CREATE INDEX idx_users_phone ON sr_auth.users(phone);
CREATE INDEX idx_users_active ON sr_auth.users(is_active) WHERE is_active = true;
CREATE INDEX idx_users_created_at ON sr_auth.users(created_at);
CREATE INDEX idx_users_deleted_at ON sr_auth.users(deleted_at) WHERE deleted_at IS NULL;

-- Create trigger for auto-updating updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON sr_auth.users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- DOWN Migration
-- DROP TRIGGER IF EXISTS update_users_updated_at ON sr_auth.users;
-- DROP TABLE IF EXISTS sr_auth.users;
