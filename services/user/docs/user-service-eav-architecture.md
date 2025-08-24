# User Service EAV Architecture

## Overview

The User Service implements an **Entity-Attribute-Value (EAV)** pattern internally while maintaining a clean, normalized external API. This document explains how normalized payloads are internally processed and stored using a shared database approach with the Auth Service.

## Architecture Principles

### 1. Clean External API
External services interact with the User Service through a simple, normalized interface. They send and receive clean JSON payloads without any knowledge of the internal EAV implementation.

### 2. Shared Database Approach
- **Auth Service**: Has full CRUD access to the shared `users` table
- **User Service**: Has read-only access to the shared `users` table and full CRUD access to EAV tables

### 3. Internal EAV Processing
The User Service internally converts normalized payloads into an EAV structure for flexible storage and retrieval of profile data.

### 4. Transparent Resolution
When retrieving user data, the service automatically resolves the EAV structure back into normalized payloads for external consumers.

## Data Flow

### 1. Create User Profile Flow

```
External Request (Normalized)
    ↓
User Service Receives Clean Payload with user_id
    ↓
Validate user_id exists in shared users table
    ↓
Extract Profile Data from request
    ↓
Process Profile Data (EAV Conversion)
    ↓
Create/Get Attribute Definitions
    ↓
Store Attribute Values in EAV Table
    ↓
Return Normalized Response
```

### 2. Retrieve User Flow

```
External Request (User ID)
    ↓
Fetch Core User Data from shared users table
    ↓
Fetch All Profile Attribute Values from EAV Table
    ↓
Resolve Attributes into Normalized Structure
    ↓
Combine Core Data + Profile Data
    ↓
Return Clean Payload to External Service
```

## Database Schema

### Schema Organization
- **Shared Schema**: `sr_auth` - Contains the shared users table
- **User Service Schema**: `sr_user` - Contains EAV tables for profile management

### Shared Users Table (Managed by Auth Service)
Located in `sr_auth` schema:
```sql
CREATE TABLE sr_auth.users (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Indexes for performance
CREATE INDEX idx_users_uuid ON sr_auth.users(uuid);
CREATE INDEX idx_users_email ON sr_auth.users(email);
CREATE INDEX idx_users_phone ON sr_auth.users(phone);
CREATE INDEX idx_users_active ON sr_auth.users(is_active) WHERE is_active = true;
CREATE INDEX idx_users_created_at ON sr_auth.users(created_at);
```

### User Attributes Table (Managed by User Service)
Located in `sr_user` schema:
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

-- Indexes for performance
CREATE INDEX idx_user_attributes_uuid ON sr_user.user_attributes(uuid);
CREATE INDEX idx_user_attributes_name ON sr_user.user_attributes(name);
CREATE INDEX idx_user_attributes_searchable ON sr_user.user_attributes(is_searchable) WHERE is_searchable = true;
CREATE INDEX idx_user_attributes_required ON sr_user.user_attributes(is_required) WHERE is_required = true;
```

### User Attribute Values Table (Managed by User Service)
Located in `sr_user` schema:
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

-- Indexes for performance
CREATE INDEX idx_user_attribute_values_uuid ON sr_user.user_attribute_values(uuid);
CREATE INDEX idx_user_attribute_values_user_uuid ON sr_user.user_attribute_values(user_uuid);
CREATE INDEX idx_user_attribute_values_attribute_id ON sr_user.user_attribute_values(attribute_id);
CREATE INDEX idx_user_attribute_values_search ON sr_user.user_attribute_values(attribute_id, value) WHERE value IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_user_attribute_values_created_at ON sr_user.user_attribute_values(created_at);
```

## Processing Logic

### 1. Attribute Definition Management
```go
// Automatically creates attribute definitions when first encountered
func (s *UserService) getOrCreateAttribute(attributeName string) (*UserAttribute, error) {
    // Check cache first
    if attr, exists := s.attributeCache[attributeName]; exists {
        return attr, nil
    }
    
    // Try to get from database
    attr, err := s.getAttributeByName(attributeName)
    if err == nil {
        s.attributeCache[attributeName] = attr
        return attr, nil
    }
    
    // Create new attribute definition
    attr = &UserAttribute{
        Name: attributeName,
        DataType: "string", // Default type
        IsRequired: false,
        IsSearchable: false,
    }
    
    err = s.createAttribute(attr)
    if err != nil {
        return nil, err
    }
    
    s.attributeCache[attributeName] = attr
    return attr, nil
}
```

### 2. EAV Storage
```go
// Stores profile data in EAV structure
func (s *UserService) storeUserAttributes(userUUID string, profileData map[string]string) error {
    for fieldName, value := range profileData {
        // Get or create attribute definition
        attr, err := s.getOrCreateAttribute(fieldName)
        if err != nil {
            return err
        }
        
        // Store the value
        err = s.storeAttributeValue(userUUID, attr.ID, value)
        if err != nil {
            return err
        }
    }
    return nil
}
```

### 3. EAV Resolution
```go
// Resolves EAV structure back to normalized payload
func (s *UserService) resolveUserWithAttributes(userUUID string) (*User, error) {
    // Get core user data from shared table
    user, err := s.getUserByUUID(userUUID)
    if err != nil {
        return nil, err
    }
    
    // Get profile attributes from EAV
    profileData, err := s.getUserAttributeValues(userUUID)
    if err != nil {
        return nil, err
    }
    
    // Combine core data with profile data
    user.ProfileData = profileData
    return user, nil
}

// Efficient attribute query
func (s *UserService) getUserAttributeValues(userUUID string) (map[string]string, error) {
    query := `
        SELECT 
            ua.name,
            uav.value
        FROM sr_user.user_attribute_values uav
        JOIN sr_user.user_attributes ua ON uav.attribute_id = ua.id
        WHERE uav.user_uuid = $1 
        AND uav.deleted_at IS NULL 
        AND ua.deleted_at IS NULL
    `
    
    rows, err := s.db.Query(query, userUUID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    profileData := make(map[string]string)
    for rows.Next() {
        var name, value string
        if err := rows.Scan(&name, &value); err != nil {
            return nil, err
        }
        profileData[name] = value
    }
    
    return profileData, nil
}
```

## External API Examples

### Create User Profile Request
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "profile_data": {
    "first_name": "John",
    "last_name": "Doe",
    "gender": "male",
    "profile_image": "https://example.com/avatar.jpg",
    "date_of_birth": "1990-01-01",
    "company": "Acme Corp",
    "address": "123 Main St"
  }
}
```

### Create User Profile Response
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "is_active": true,
    "created_at": "2024-01-01T00:00:00Z",
    "profile_data": {
      "first_name": "John",
      "last_name": "Doe",
      "gender": "male",
      "profile_image": "https://example.com/avatar.jpg",
      "date_of_birth": "1990-01-01",
      "company": "Acme Corp",
      "address": "123 Main St"
    }
  },
  "message": "User profile created successfully"
}
```

### Get User Request
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Get User Response
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "john.doe@example.com",
    "phone": "+1234567890",
    "is_active": true,
    "created_at": "2024-01-01T00:00:00Z",
    "profile_data": {
      "first_name": "John",
      "last_name": "Doe",
      "gender": "male",
      "profile_image": "https://example.com/avatar.jpg",
      "date_of_birth": "1990-01-01",
      "company": "Acme Corp",
      "address": "123 Main St"
    }
  }
}
```

## Service Integration

### Auth Service Integration
```go
// User Service validates user exists before creating profile
func (s *UserService) CreateUserProfile(ctx context.Context, req *CreateUserProfileRequest) (*CreateUserProfileResponse, error) {
    // First, verify user exists in shared table
    user, err := s.getUserByUUID(req.UserId)
    if err != nil {
        return nil, status.Errorf(codes.NotFound, "User not found: %v", err)
    }
    
    // Store profile data in EAV
    if len(req.ProfileData) > 0 {
        err = s.storeUserAttributes(req.UserId, req.ProfileData)
        if err != nil {
            return nil, status.Errorf(codes.Internal, "Failed to store profile data: %v", err)
        }
    }
    
    // Return complete user data
    completeUser, err := s.resolveUserWithAttributes(req.UserId)
    if err != nil {
        return nil, status.Errorf(codes.Internal, "Failed to resolve user data: %v", err)
    }
    
    return &CreateUserProfileResponse{
        User: completeUser,
        Message: "User profile created successfully",
    }, nil
}
```

### Application Service Integration
```go
// Application service calls user service - no EAV knowledge needed
func (s *UserAppService) CreateUserProfile(req *CreateUserProfileRequest) (*CreateUserProfileResponse, error) {
    // Call user service with simple payload
    userReq := &user.CreateUserProfileRequest{
        UserId: req.UserId,
        ProfileData: map[string]string{
            "first_name": req.FirstName,
            "last_name": req.LastName,
            "gender": req.Gender,
            "profile_image": req.ProfileImage,
            "phone": req.Phone,
            "date_of_birth": req.DateOfBirth,
        },
    }
    
    userResp, err := s.userServiceClient.CreateUserProfile(ctx, userReq)
    if err != nil {
        return nil, err
    }
    
    // Return clean response
    return &CreateUserProfileResponse{
        User: &User{
            ID: userResp.User.Id,
            Email: userResp.User.Email,
            FirstName: userResp.User.ProfileData["first_name"],
            LastName: userResp.User.ProfileData["last_name"],
            // ... other fields
        },
    }, nil
}
```

## Performance Optimizations

### 1. Caching Strategy
```go
// Redis caching for frequently accessed data
type UserService struct {
    db *sql.DB
    redis *redis.Client
    attributeCache map[string]*UserAttribute
}

func (s *UserService) getUserWithCache(userID string) (*User, error) {
    // Try cache first
    cacheKey := fmt.Sprintf("user:%s", userID)
    cached, err := s.redis.Get(cacheKey).Result()
    if err == nil {
        var user User
        json.Unmarshal([]byte(cached), &user)
        return &user, nil
    }
    
    // Fetch from database
    user, err := s.resolveUserWithAttributes(userID)
    if err != nil {
        return nil, err
    }
    
    // Cache for 5 minutes
    userJSON, _ := json.Marshal(user)
    s.redis.Set(cacheKey, userJSON, 5*time.Minute)
    
    return user, nil
}
```

### 2. Batch Operations
```go
// Efficient batch attribute storage
func (s *UserService) storeUserAttributesBatch(userUUID string, profileData map[string]string) error {
    tx, err := s.db.Begin()
    if err != nil {
        return err
    }
    defer tx.Rollback()
    
    stmt, err := tx.Prepare(`
        INSERT INTO sr_user.user_attribute_values (uuid, user_uuid, attribute_id, value, meta, created_at, updated_at)
        VALUES (gen_random_uuid(), $1, $2, $3, '{}', NOW(), NOW())
        ON CONFLICT (user_uuid, attribute_id) 
        DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()
    `)
    if err != nil {
        return err
    }
    defer stmt.Close()
    
    for fieldName, value := range profileData {
        attr, err := s.getOrCreateAttribute(fieldName)
        if err != nil {
            return err
        }
        
        _, err = stmt.Exec(userUUID, attr.ID, value)
        if err != nil {
            return err
        }
    }
    
    return tx.Commit()
}
```

## Database Utilities and Optimization

### Auto-Update Triggers
The system includes automatic triggers to update the `updated_at` column whenever a record is modified:

```sql
-- Utility function for auto-updating updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for auto-updating updated_at
CREATE TRIGGER update_user_attributes_updated_at 
    BEFORE UPDATE ON sr_user.user_attributes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_attribute_values_updated_at 
    BEFORE UPDATE ON sr_user.user_attribute_values 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Soft Delete Implementation
All tables implement soft delete behavior using the `deleted_at` column:

```sql
-- Example: Soft delete a user attribute value
UPDATE sr_user.user_attribute_values 
SET deleted_at = NOW() 
WHERE user_uuid = $1 AND attribute_id = $2;

-- Example: Query excluding soft-deleted records
SELECT * FROM sr_user.user_attribute_values 
WHERE deleted_at IS NULL;
```

### Performance Indexes
Optimized indexes for common query patterns:

```sql
-- Core performance indexes
CREATE INDEX idx_users_uuid ON sr_auth.users(uuid);
CREATE INDEX idx_users_email ON sr_auth.users(email);
CREATE INDEX idx_users_active ON sr_auth.users(is_active) WHERE is_active = true;

CREATE INDEX idx_user_attributes_name ON sr_user.user_attributes(name);
CREATE INDEX idx_user_attributes_searchable ON sr_user.user_attributes(is_searchable) WHERE is_searchable = true;

CREATE INDEX idx_user_attribute_values_user_uuid ON sr_user.user_attribute_values(user_uuid);
CREATE INDEX idx_user_attribute_values_search ON sr_user.user_attribute_values(attribute_id, value) WHERE value IS NOT NULL AND deleted_at IS NULL;
```

## Migration Strategy

### Initial Setup
```sql
-- Create schemas if they don't exist
CREATE SCHEMA IF NOT EXISTS sr_auth;
CREATE SCHEMA IF NOT EXISTS sr_user;

-- Create utility function for auto-updating updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create EAV tables in sr_user schema
CREATE TABLE sr_user.user_attributes (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    data_type VARCHAR(50) NOT NULL,
    is_required BOOLEAN DEFAULT false,
    is_searchable BOOLEAN DEFAULT false,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

CREATE TABLE sr_user.user_attribute_values (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    user_uuid UUID NOT NULL,
    attribute_id INTEGER NOT NULL REFERENCES sr_user.user_attributes(id) ON DELETE CASCADE,
    value TEXT,
    meta JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ DEFAULT NULL,
    UNIQUE(user_uuid, attribute_id)
);

-- Create triggers for auto-updating updated_at
CREATE TRIGGER update_user_attributes_updated_at 
    BEFORE UPDATE ON sr_user.user_attributes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_attribute_values_updated_at 
    BEFORE UPDATE ON sr_user.user_attribute_values 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Pre-configure common attributes
INSERT INTO sr_user.user_attributes (uuid, name, data_type, is_required, is_searchable, meta, created_at, updated_at) VALUES
(gen_random_uuid(), 'first_name', 'string', true, true, '{"display_name": "First Name", "validation": {"min_length": 1, "max_length": 50}}', NOW(), NOW()),
(gen_random_uuid(), 'last_name', 'string', true, true, '{"display_name": "Last Name", "validation": {"min_length": 1, "max_length": 50}}', NOW(), NOW()),
(gen_random_uuid(), 'gender', 'string', false, false, '{"display_name": "Gender", "options": ["male", "female", "other"]}', NOW(), NOW()),
(gen_random_uuid(), 'profile_image', 'string', false, false, '{"display_name": "Profile Image", "validation": {"pattern": "^https?://.*"}}', NOW(), NOW()),
(gen_random_uuid(), 'date_of_birth', 'date', false, false, '{"display_name": "Date of Birth"}', NOW(), NOW()),
(gen_random_uuid(), 'company', 'string', false, false, '{"display_name": "Company", "validation": {"max_length": 100}}', NOW(), NOW()),
(gen_random_uuid(), 'address', 'string', false, false, '{"display_name": "Address", "validation": {"max_length": 200}}', NOW(), NOW());
```

## Benefits of This Approach

1. **Clean External API**: Application services see a simple, clean interface
2. **Internal Flexibility**: User service can handle any profile attributes without API changes
3. **Shared Identity**: Single source of truth for core user data
4. **Clear Separation**: Auth service manages identity, User service manages profiles
5. **Performance**: Optimized queries and caching for production workloads
6. **Scalability**: Efficient handling of diverse profile data requirements
7. **Maintainability**: Clean separation between internal storage and external API
8. **Multi-Tenancy**: Single service can serve multiple applications with different needs

## Considerations

1. **Data Consistency**: Ensure user exists in auth service before creating profile
2. **Performance**: Use caching and optimized queries for EAV operations
3. **Search**: Implement full-text search on searchable attributes
4. **Validation**: Server-side validation based on attribute definitions
5. **Migration**: Provide tools to migrate existing user data to EAV structure
