# User Service Database Migrations

This directory contains database migration scripts for the User Service, which implements an Entity-Attribute-Value (EAV) pattern for flexible user profile management.

## Migration Files

### 001_create_schemas.sql
- Creates the `sr_user` schema
- This is the foundation schema for all User Service tables

### 002_create_utility_functions.sql
- **DEPRECATED**: Utility functions are now in global migrations
- This file is kept for reference but should not be executed
- See: `/migrations/002_create_utility_functions.sql` for current utility functions

### 003_create_user_attributes_table.sql
- Creates the `user_attributes` table for defining available profile attributes
- Supports dynamic attribute creation for flexible user profiles
- Includes validation metadata and search configuration

### 004_create_user_attribute_values_table.sql
- Creates the `user_attribute_values` table for storing actual profile data
- Implements the EAV pattern for flexible user attributes
- References the shared `users` table from Auth Service (no FK constraint)

### 005_insert_default_attributes.sql
- Pre-configures common user profile attributes
- Includes validation rules and display names
- Provides a foundation for user profile management

## Table Structure

### user_attributes Table
```sql
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
```

### user_attribute_values Table
```sql
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
```

## Pre-configured Attributes

The migration includes 20 common user profile attributes:

### Required Attributes
- `first_name` (string, required, searchable)
- `last_name` (string, required, searchable)

### Optional Attributes
- `gender` (string, with predefined options)
- `profile_image` (string, URL validation)
- `date_of_birth` (date)
- `company` (string)
- `address` (string)
- `bio` (string)
- `preferences` (string)
- `timezone` (string)

## Running Migrations

### Prerequisites
- PostgreSQL database
- **Global migrations must be run first** (extensions and utility functions)
- **Auth Service migrations must be run second** (shared users table)
- Database user with CREATE SCHEMA and CREATE TABLE permissions

### Manual Execution
```bash
# Connect to your PostgreSQL database
psql -h localhost -U your_user -d your_database

# Run migrations in order
\i 001_create_schemas.sql
\i 002_create_user_attributes_table.sql
\i 003_create_user_attribute_values_table.sql
\i 004_insert_default_attributes.sql
```

### Using a Migration Tool
If you're using a migration tool like golang-migrate, you can run:
```bash
migrate -path ./services/user/migrations -database "postgres://user:password@localhost/dbname?sslmode=disable" up
```

## Migration Order

**IMPORTANT**: Migrations must be run in this specific order:

```bash
# 1. Run global migrations first
cd ../../migrations
psql -h localhost -U your_user -d your_database -f 001_install_extensions.sql
psql -h localhost -U your_user -d your_database -f 002_create_utility_functions.sql
psql -h localhost -U your_user -d your_database -f 003_create_common_indexes.sql

# 2. Run Auth Service migrations
cd ../services/auth/migrations
psql -h localhost -U your_user -d your_database -f 001_create_schemas.sql
psql -h localhost -U your_user -d your_database -f 002_create_users_table.sql

# 3. Run User Service migrations
cd ../../user/migrations
psql -h localhost -U your_user -d your_database -f 001_create_schemas.sql
psql -h localhost -U your_user -d your_database -f 002_create_user_attributes_table.sql
psql -h localhost -U your_user -d your_database -f 003_create_user_attribute_values_table.sql
psql -h localhost -U your_user -d your_database -f 004_insert_default_attributes.sql
```

## Rollback
To rollback migrations, uncomment the DOWN migration sections in each file and run them in reverse order:
```bash
# Rollback in reverse order
\i 004_insert_default_attributes.sql  # Uncomment DOWN section
\i 003_create_user_attribute_values_table.sql  # Uncomment DOWN section
\i 002_create_user_attributes_table.sql  # Uncomment DOWN section
\i 001_create_schemas.sql  # Uncomment DOWN section
```

## EAV Architecture Benefits

1. **Flexible Schema**: Add new profile attributes without database migrations
2. **Clean API**: External services see normalized payloads
3. **Shared Identity**: Reads core user data from Auth Service
4. **Performance**: Optimized queries with caching
5. **Multi-Application Support**: Single service can serve multiple applications

## Notes

- The User Service has read-only access to the shared `users` table in `sr_auth` schema
- All tables implement soft delete using the `deleted_at` column
- Automatic `updated_at` timestamps are handled by triggers
- Performance indexes are created for common query patterns
- The EAV pattern allows for dynamic attribute creation at runtime
- Attribute definitions include validation rules and metadata
