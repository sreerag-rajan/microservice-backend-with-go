-- Migration: 004_create_otp_tokens_table
-- Description: Create OTP tokens table for managing OTP generation and validation
-- Created: 2024-01-01

-- UP Migration
CREATE TABLE sr_auth.otp_tokens (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES sr_auth.users(id) ON DELETE CASCADE,
    otp_code VARCHAR(10) NOT NULL,
    use_case VARCHAR(50) NOT NULL, -- 'email_verification', 'phone_verification', 'password_reset', 'two_factor'
    is_used BOOLEAN DEFAULT false,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ DEFAULT NULL,
    meta JSONB DEFAULT '{}', -- Additional metadata like device info, IP, etc.
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_otp_tokens_user_id ON sr_auth.otp_tokens(user_id);
CREATE INDEX idx_otp_tokens_otp_code ON sr_auth.otp_tokens(otp_code);
CREATE INDEX idx_otp_tokens_use_case ON sr_auth.otp_tokens(use_case);
CREATE INDEX idx_otp_tokens_expires_at ON sr_auth.otp_tokens(expires_at);
CREATE INDEX idx_otp_tokens_unused ON sr_auth.otp_tokens(user_id, use_case, is_used) WHERE is_used = false;
CREATE INDEX idx_otp_tokens_created_at ON sr_auth.otp_tokens(created_at);

-- Create trigger for auto-updating updated_at
CREATE TRIGGER update_otp_tokens_updated_at 
    BEFORE UPDATE ON sr_auth.otp_tokens 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- DOWN Migration
-- DROP TRIGGER IF EXISTS update_otp_tokens_updated_at ON sr_auth.otp_tokens;
-- DROP TABLE IF EXISTS sr_auth.otp_tokens;
