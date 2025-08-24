-- Migration: 004_create_user_attribute_values_table
-- Description: Create user_attribute_values table for storing actual profile attribute values
-- Created: 2024-01-01

-- UP Migration
CREATE TABLE sr_user.user_attribute_values (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    user_uuid UUID NOT NULL, -- References shared users table (no FK constraint)
    attribute_id INTEGER NOT NULL REFERENCES sr_user.user_attributes(id) ON DELETE CASCADE,
    value TEXT,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ DEFAULT NULL,
    UNIQUE(user_uuid, attribute_id)
);

-- Create indexes for performance
CREATE INDEX idx_user_attribute_values_uuid ON sr_user.user_attribute_values(uuid);
CREATE INDEX idx_user_attribute_values_user_uuid ON sr_user.user_attribute_values(user_uuid);
CREATE INDEX idx_user_attribute_values_attribute_id ON sr_user.user_attribute_values(attribute_id);
CREATE INDEX idx_user_attribute_values_search ON sr_user.user_attribute_values(attribute_id, value) WHERE value IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_user_attribute_values_created_at ON sr_user.user_attribute_values(created_at);
CREATE INDEX idx_user_attribute_values_deleted_at ON sr_user.user_attribute_values(deleted_at) WHERE deleted_at IS NULL;

-- Create trigger for auto-updating updated_at
CREATE TRIGGER update_user_attribute_values_updated_at 
    BEFORE UPDATE ON sr_user.user_attribute_values 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- DOWN Migration
-- DROP TRIGGER IF EXISTS update_user_attribute_values_updated_at ON sr_user.user_attribute_values;
-- DROP TABLE IF EXISTS sr_user.user_attribute_values;
