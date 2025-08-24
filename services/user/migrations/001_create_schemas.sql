-- Migration: 001_create_schemas
-- Description: Create sr_user schema for User Service
-- Created: 2024-01-01

-- UP Migration
CREATE SCHEMA IF NOT EXISTS sr_user;

-- DOWN Migration
-- DROP SCHEMA IF EXISTS sr_user CASCADE;
