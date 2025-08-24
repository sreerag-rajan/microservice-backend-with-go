-- Migration: 003_create_common_indexes
-- Description: Create common index patterns and performance optimizations
-- Created: 2024-01-01

-- UP Migration

-- Create a function to add common indexes to any table
CREATE OR REPLACE FUNCTION add_common_indexes(
    schema_name TEXT,
    table_name TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Add UUID index
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_uuid ON %I.%I(uuid)', table_name, schema_name, table_name);
    
    -- Add created_at index
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_created_at ON %I.%I(created_at)', table_name, schema_name, table_name);
    
    -- Add updated_at index
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_updated_at ON %I.%I(updated_at)', table_name, schema_name, table_name);
    
    -- Add soft delete index (only for non-deleted records)
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_deleted_at ON %I.%I(deleted_at) WHERE deleted_at IS NULL', table_name, schema_name, table_name);
    
    -- Add composite index for common query patterns
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_active_created ON %I.%I(is_active, created_at) WHERE is_active = true AND deleted_at IS NULL', table_name, schema_name, table_name);
END;
$$ language 'plpgsql';

-- Create a function to add UUID-based foreign key indexes
CREATE OR REPLACE FUNCTION add_uuid_fk_indexes(
    schema_name TEXT,
    table_name TEXT,
    column_name TEXT
)
RETURNS VOID AS $$
BEGIN
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_%I ON %I.%I(%I)', table_name, column_name, schema_name, table_name, column_name);
END;
$$ language 'plpgsql';

-- Create a function to add search indexes for text columns
CREATE OR REPLACE FUNCTION add_search_index(
    schema_name TEXT,
    table_name TEXT,
    column_name TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Add GIN index for full-text search
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_%I_gin ON %I.%I USING gin(to_tsvector(''english'', %I))', 
                   table_name, column_name, schema_name, table_name, column_name);
    
    -- Add trigram index for similarity search
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_%I_trgm ON %I.%I USING gin(%I gin_trgm_ops)', 
                   table_name, column_name, schema_name, table_name, column_name);
END;
$$ language 'plpgsql';

-- DOWN Migration
-- DROP FUNCTION IF EXISTS add_search_index(TEXT, TEXT, TEXT);
-- DROP FUNCTION IF EXISTS add_uuid_fk_indexes(TEXT, TEXT, TEXT);
-- DROP FUNCTION IF EXISTS add_common_indexes(TEXT, TEXT);
