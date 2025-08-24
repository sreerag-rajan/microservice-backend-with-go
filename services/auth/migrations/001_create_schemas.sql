-- Migration: 001_create_schemas
-- Description: Create sr_auth schema for Auth Service
-- Created: 2024-01-01

-- UP Migration
CREATE SCHEMA IF NOT EXISTS sr_auth;

-- DOWN Migration
-- DROP SCHEMA IF EXISTS sr_auth CASCADE;
