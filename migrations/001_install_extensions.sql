-- Migration: 001_install_extensions
-- Description: Install PostgreSQL extensions needed across all services
-- Created: 2024-01-01

-- UP Migration
-- Install uuid-ossp extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Install pgcrypto extension for cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Install btree_gin extension for GIN indexes on UUID columns
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Install unaccent extension for text search (optional)
-- CREATE EXTENSION IF NOT EXISTS "unaccent";

-- DOWN Migration
-- DROP EXTENSION IF EXISTS "btree_gin";
-- DROP EXTENSION IF EXISTS "pgcrypto";
-- DROP EXTENSION IF EXISTS "uuid-ossp";
