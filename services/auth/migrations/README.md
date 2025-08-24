# Auth Service Database Migrations

## Overview

This directory contains the database migrations for the Auth Service. The migrations have been consolidated into a single comprehensive migration file to simplify the setup process for new developers.

## Migration Files

### Current Migration
- **`001_create_auth_schema.sql`** - Complete Auth Service schema creation with all tables, indexes, and initial data

### Dependencies
This migration depends on the global migrations in the `/migrations/` directory:
1. `001_install_extensions.sql` - Installs required PostgreSQL extensions
2. `002_create_utility_functions.sql` - Creates common utility functions
3. `003_create_common_indexes.sql` - Creates index utility functions

## Migration Order

**IMPORTANT**: Global migrations must be run BEFORE the auth service migration:

1. Run global migrations first:
   ```bash
   psql -d your_database -f /migrations/001_install_extensions.sql
   psql -d your_database -f /migrations/002_create_utility_functions.sql
   psql -d your_database -f /migrations/003_create_common_indexes.sql
   ```

2. Run auth service migration:
   ```bash
   psql -d your_database -f services/auth/migrations/001_create_auth_schema.sql
   ```

## Schema Structure

The Auth Service uses the `sr_auth` schema and includes the following tables:

### Core Tables
- **`users`** - User accounts and authentication information
- **`otp_tokens`** - One-time password tokens for verification
- **`sessions`** - User login sessions and refresh tokens
- **`login_logs`** - Audit trail for login attempts and security events
- **`devices`** - User device management and trust status
- **`providers`** - OAuth provider configurations
- **`user_providers`** - User OAuth provider relationships

### Standard Fields
All tables include the following standard fields as per the db-table-creation-rules:
- `id` - Integer primary key
- `uuid` - UUID unique identifier
- `meta` - JSONB for additional metadata
- `created_at` - Timestamp when record was created
- `updated_at` - Timestamp when record was last updated
- `deleted_at` - Timestamp for soft deletes (NULL = active)

## Compliance with Database Rules

This migration follows all the db-table-creation-rules:

### ✅ Standard Fields
- All tables include the required standard fields (`id`, `uuid`, `meta`, `created_at`, `updated_at`, `deleted_at`)
- Uses `generate_uuid()` function for UUID generation
- Uses `get_utc_timestamp()` function for timestamps

### ✅ Global Utility Functions
- Uses `add_common_indexes()` function for standard indexes
- Uses `update_updated_at_column()` function for auto-updating timestamps
- Leverages global utility functions instead of manual implementations

### ✅ Indexing Strategy
- Common indexes added using global utility functions
- Service-specific indexes added manually where needed
- Proper indexing for foreign keys and frequently queried columns

### ✅ Soft Delete Support
- All tables support soft deletes via `deleted_at` field
- Indexes properly handle soft delete queries
- Global soft delete utility functions can be used

## Initial Data

The migration includes initial OAuth provider configurations for:
- Google
- Microsoft
- GitHub
- Facebook
- Apple
- LinkedIn

All providers are disabled by default and require configuration of client credentials.

## Rollback

The migration includes a complete DOWN migration section (commented out) that can be used to rollback all changes if needed.

## Previous Migration Files

The following migration files have been consolidated and should be removed:
- `001_create_schemas.sql`
- `002_create_users_table.sql`
- `003_add_is_verified_to_users.sql`
- `004_create_otp_tokens_table.sql`
- `005_create_sessions_table.sql`
- `006_create_login_logs_table.sql`
- `007_create_devices_table.sql`
- `008_create_providers_table.sql`
- `009_create_user_providers_table.sql`
- `010_add_oauth_fields_to_users.sql`

## Usage

### For New Development
1. Ensure global migrations are applied
2. Run the consolidated migration: `001_create_auth_schema.sql`
3. The auth service database is ready to use

### For Existing Development
If you have already run the previous migration files, you can:
1. Drop the existing `sr_auth` schema
2. Run the consolidated migration
3. Or continue using the existing schema (the consolidated migration is idempotent)

## Validation

After running the migration, you can validate the setup:

```sql
-- Check that all tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'sr_auth' 
ORDER BY table_name;

-- Check that all standard fields exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'sr_auth' 
AND table_name = 'users'
ORDER BY ordinal_position;

-- Check that indexes are created
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'sr_auth'
ORDER BY tablename, indexname;
```
