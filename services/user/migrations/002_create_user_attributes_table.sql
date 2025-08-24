-- Migration: 003_create_user_attributes_table
-- Description: Create user_attributes table for defining available profile attributes
-- Created: 2024-01-01

-- UP Migration
CREATE TABLE sr_user.user_attributes (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    data_type VARCHAR(50) NOT NULL, -- 'string', 'integer', 'boolean', 'date'
    is_required BOOLEAN DEFAULT false,
    is_searchable BOOLEAN DEFAULT false,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Create indexes for performance
CREATE INDEX idx_user_attributes_uuid ON sr_user.user_attributes(uuid);
CREATE INDEX idx_user_attributes_name ON sr_user.user_attributes(name);
CREATE INDEX idx_user_attributes_searchable ON sr_user.user_attributes(is_searchable) WHERE is_searchable = true;
CREATE INDEX idx_user_attributes_required ON sr_user.user_attributes(is_required) WHERE is_required = true;
CREATE INDEX idx_user_attributes_deleted_at ON sr_user.user_attributes(deleted_at) WHERE deleted_at IS NULL;

-- Create trigger for auto-updating updated_at
CREATE TRIGGER update_user_attributes_updated_at 
    BEFORE UPDATE ON sr_user.user_attributes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- DOWN Migration
-- DROP TRIGGER IF EXISTS update_user_attributes_updated_at ON sr_user.user_attributes;
-- DROP TABLE IF EXISTS sr_user.user_attributes;
