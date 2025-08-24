-- Migration: 005_insert_default_attributes
-- Description: Insert common attribute definitions for user profiles
-- Created: 2024-01-01

-- UP Migration
INSERT INTO sr_user.user_attributes (uuid, name, data_type, is_required, is_searchable, meta, created_at, updated_at) VALUES
(gen_random_uuid(), 'first_name', 'string', true, true, '{"display_name": "First Name", "validation": {"min_length": 1, "max_length": 50}}', NOW(), NOW()),
(gen_random_uuid(), 'last_name', 'string', true, true, '{"display_name": "Last Name", "validation": {"min_length": 1, "max_length": 50}}', NOW(), NOW()),
(gen_random_uuid(), 'gender', 'string', false, true, '{"display_name": "Gender", "options": ["male", "female", "other"]}', NOW(), NOW()),
(gen_random_uuid(), 'profile_image', 'string', false, false, '{"display_name": "Profile Image", "validation": {"pattern": "^https?://.*"}}', NOW(), NOW()),
(gen_random_uuid(), 'date_of_birth', 'date', false, true, '{"display_name": "Date of Birth"}', NOW(), NOW()),
(gen_random_uuid(), 'bio', 'string', false, false, '{"display_name": "Bio", "validation": {"max_length": 500}}', NOW(), NOW()),
(gen_random_uuid(), 'preferences', 'string', false, false, '{"display_name": "User Preferences", "validation": {"max_length": 1000}}', NOW(), NOW()),
(gen_random_uuid(), 'timezone', 'string', false, false, '{"display_name": "Timezone", "validation": {"max_length": 50}}', NOW(), NOW());

-- DOWN Migration
-- DELETE FROM sr_user.user_attributes WHERE name IN (
--     'first_name', 'last_name', 'gender', 'profile_image', 'date_of_birth', 'company', 'address',
--     'bio', 'website', 'location', 'job_title', 'department', 'hire_date', 'salary_range',
--     'skills', 'interests', 'social_media', 'emergency_contact', 'preferences', 'timezone'
-- );
