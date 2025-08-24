# Global Database Migrations

This directory contains global database migrations that are shared across all services. These migrations set up common infrastructure, extensions, and utility functions that all services depend on.

## Migration Files

### 001_install_extensions.sql
- Installs PostgreSQL extensions needed across all services
- **uuid-ossp**: For UUID generation (`gen_random_uuid()`)
- **pgcrypto**: For cryptographic functions
- **btree_gin**: For GIN indexes on UUID columns
- **unaccent**: For text search (commented out, enable if needed)

### 002_create_utility_functions.sql
- Creates common utility functions used across all services
- **update_updated_at_column()**: Auto-updates `updated_at` timestamp
- **generate_uuid()**: Wrapper for `gen_random_uuid()`
- **is_valid_uuid()**: Validates UUID format
- **get_utc_timestamp()**: Returns current UTC timestamp
- **soft_delete_record()**: Generic soft delete function
- **restore_deleted_record()**: Restores soft deleted records
- **record_exists_and_active()**: Checks if record exists and is active

### 003_create_common_indexes.sql
- Creates utility functions for adding common indexes
- **add_common_indexes()**: Adds standard indexes (uuid, created_at, updated_at, deleted_at)
- **add_uuid_fk_indexes()**: Adds indexes for UUID foreign keys
- **add_search_index()**: Adds full-text and trigram search indexes

## Migration Order

**IMPORTANT**: Global migrations must be run BEFORE any service-specific migrations:

```bash
# 1. Run global migrations first
cd migrations
psql -h localhost -U your_user -d your_database -f 001_install_extensions.sql
psql -h localhost -U your_user -d your_database -f 002_create_utility_functions.sql
psql -h localhost -U your_user -d your_database -f 003_create_common_indexes.sql

# 2. Then run service migrations
cd ../services/auth/migrations
# ... run auth service migrations

cd ../../services/user/migrations
# ... run user service migrations
```

## Usage Examples

### Using Utility Functions in Service Migrations

```sql
-- In a service migration, you can now use the global functions
CREATE TABLE my_service.my_table (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT generate_uuid(),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    updated_at TIMESTAMPTZ DEFAULT get_utc_timestamp(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Add common indexes using the utility function
SELECT add_common_indexes('my_service', 'my_table');

-- Add search index for name column
SELECT add_search_index('my_service', 'my_table', 'name');
```

### Using Soft Delete Functions

```sql
-- Soft delete a record
SELECT soft_delete_record('my_service.my_table', 123);

-- Restore a soft deleted record
SELECT restore_deleted_record('my_service.my_table', 123);

-- Check if record exists and is active
SELECT record_exists_and_active('my_service.my_table', 123);
```

## Benefits

1. **DRY Principle**: No duplication of utility functions across services
2. **Consistency**: All services use the same utility functions
3. **Maintainability**: Update utilities in one place
4. **Performance**: Optimized functions and indexes
5. **Standardization**: Common patterns across all services

## Dependencies

- PostgreSQL 12+ (for `gen_random_uuid()`)
- Superuser privileges for extension installation
- Regular user privileges for function creation

## Rollback

To rollback global migrations, uncomment the DOWN migration sections and run in reverse order:

```bash
# Rollback in reverse order
psql -h localhost -U your_user -d your_database -f 003_create_common_indexes.sql  # Uncomment DOWN section
psql -h localhost -U your_user -d your_database -f 002_create_utility_functions.sql  # Uncomment DOWN section
psql -h localhost -U your_user -d your_database -f 001_install_extensions.sql  # Uncomment DOWN section
```

## Notes

- Global migrations are idempotent (safe to run multiple times)
- Extensions are installed at database level, not schema level
- Functions are created in the public schema for global access
- All functions include proper error handling and validation
