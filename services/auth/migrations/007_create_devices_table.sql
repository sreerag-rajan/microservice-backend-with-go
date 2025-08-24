-- Migration: 007_create_devices_table
-- Description: Create devices table for managing user devices, trust status, and device-specific settings
-- Created: 2024-01-01

-- UP Migration
CREATE TABLE sr_auth.devices (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES sr_auth.users(id) ON DELETE CASCADE,
    device_name VARCHAR(255), -- User-friendly device name
    device_type VARCHAR(50), -- 'mobile', 'desktop', 'tablet', 'unknown'
    device_id VARCHAR(255), -- Unique device identifier (fingerprint)
    browser VARCHAR(100),
    os VARCHAR(100),
    ip_address INET,
    is_trusted BOOLEAN DEFAULT false, -- Whether this device is trusted (skip 2FA)
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    trusted_at TIMESTAMPTZ DEFAULT NULL, -- When the device was marked as trusted
    meta JSONB DEFAULT '{}', -- Additional device metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_devices_user_id ON sr_auth.devices(user_id);
CREATE INDEX idx_devices_device_id ON sr_auth.devices(device_id);
CREATE INDEX idx_devices_trusted ON sr_auth.devices(is_trusted) WHERE is_trusted = true;
CREATE INDEX idx_devices_active ON sr_auth.devices(is_active) WHERE is_active = true;
CREATE INDEX idx_devices_last_used_at ON sr_auth.devices(last_used_at);
CREATE INDEX idx_devices_created_at ON sr_auth.devices(created_at);

-- Create unique constraint for user-device combination
CREATE UNIQUE INDEX idx_devices_user_device ON sr_auth.devices(user_id, device_id) WHERE device_id IS NOT NULL;

-- Create trigger for auto-updating updated_at
CREATE TRIGGER update_devices_updated_at 
    BEFORE UPDATE ON sr_auth.devices 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- DOWN Migration
-- DROP TRIGGER IF EXISTS update_devices_updated_at ON sr_auth.devices;
-- DROP TABLE IF EXISTS sr_auth.devices;
