-- Migration: 006_create_login_logs_table
-- Description: Create login logs table for tracking login attempts, security events, and audit trail
-- Created: 2024-01-01

-- UP Migration
CREATE TABLE sr_auth.login_logs (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    user_id INTEGER REFERENCES sr_auth.users(id) ON DELETE SET NULL, -- NULL for failed login attempts
    session_id INTEGER REFERENCES sr_auth.sessions(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL, -- 'login_success', 'login_failed', 'logout', 'session_expired', 'password_changed', 'account_locked'
    ip_address INET,
    user_agent TEXT,
    device_info JSONB DEFAULT '{}',
    success BOOLEAN NOT NULL,
    failure_reason VARCHAR(255), -- Reason for failed login attempts
    meta JSONB DEFAULT '{}', -- Additional event metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance and security monitoring
CREATE INDEX idx_login_logs_user_id ON sr_auth.login_logs(user_id);
CREATE INDEX idx_login_logs_session_id ON sr_auth.login_logs(session_id);
CREATE INDEX idx_login_logs_event_type ON sr_auth.login_logs(event_type);
CREATE INDEX idx_login_logs_success ON sr_auth.login_logs(success);
CREATE INDEX idx_login_logs_ip_address ON sr_auth.login_logs(ip_address);
CREATE INDEX idx_login_logs_created_at ON sr_auth.login_logs(created_at);
CREATE INDEX idx_login_logs_user_events ON sr_auth.login_logs(user_id, event_type, created_at);

-- DOWN Migration
-- DROP TABLE IF EXISTS sr_auth.login_logs;
