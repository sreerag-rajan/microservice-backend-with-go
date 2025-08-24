-- Migration: 002_create_utility_functions
-- Description: Create common utility functions for auto-updating updated_at column and other shared utilities
-- Created: 2024-01-01

-- UP Migration

-- Function to auto-update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to generate a random UUID
CREATE OR REPLACE FUNCTION generate_uuid()
RETURNS UUID AS $$
BEGIN
    RETURN gen_random_uuid();
END;
$$ language 'plpgsql';

-- Function to check if a UUID is valid
CREATE OR REPLACE FUNCTION is_valid_uuid(uuid_string TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN uuid_string ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
END;
$$ language 'plpgsql';

-- Function to get current timestamp in UTC
CREATE OR REPLACE FUNCTION get_utc_timestamp()
RETURNS TIMESTAMPTZ AS $$
BEGIN
    RETURN NOW() AT TIME ZONE 'UTC';
END;
$$ language 'plpgsql';

-- Function to soft delete a record
CREATE OR REPLACE FUNCTION soft_delete_record(table_name TEXT, record_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    query TEXT;
    result BOOLEAN;
BEGIN
    query := format('UPDATE %I SET deleted_at = NOW() WHERE id = $1 AND deleted_at IS NULL', table_name);
    EXECUTE query USING record_id;
    
    GET DIAGNOSTICS result = ROW_COUNT;
    RETURN result > 0;
END;
$$ language 'plpgsql';

-- Function to restore a soft deleted record
CREATE OR REPLACE FUNCTION restore_deleted_record(table_name TEXT, record_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    query TEXT;
    result BOOLEAN;
BEGIN
    query := format('UPDATE %I SET deleted_at = NULL WHERE id = $1 AND deleted_at IS NOT NULL', table_name);
    EXECUTE query USING record_id;
    
    GET DIAGNOSTICS result = ROW_COUNT;
    RETURN result > 0;
END;
$$ language 'plpgsql';

-- Function to check if a record exists and is not soft deleted
CREATE OR REPLACE FUNCTION record_exists_and_active(table_name TEXT, record_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    query TEXT;
    result BOOLEAN;
BEGIN
    query := format('SELECT EXISTS(SELECT 1 FROM %I WHERE id = $1 AND deleted_at IS NULL)', table_name);
    EXECUTE query INTO result USING record_id;
    RETURN result;
END;
$$ language 'plpgsql';

-- DOWN Migration
-- DROP FUNCTION IF EXISTS record_exists_and_active(TEXT, INTEGER);
-- DROP FUNCTION IF EXISTS restore_deleted_record(TEXT, INTEGER);
-- DROP FUNCTION IF EXISTS soft_delete_record(TEXT, INTEGER);
-- DROP FUNCTION IF EXISTS get_utc_timestamp();
-- DROP FUNCTION IF EXISTS is_valid_uuid(TEXT);
-- DROP FUNCTION IF EXISTS generate_uuid();
-- DROP FUNCTION IF EXISTS update_updated_at_column();
