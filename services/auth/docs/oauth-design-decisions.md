# OAuth Design Decisions & Architecture

This document explains the design decisions behind the OAuth implementation in the Auth Service, particularly focusing on the `user_providers` table and why we chose a flexible multi-provider approach.

## 🎯 **Overview**

The Auth Service supports OAuth authentication with multiple providers (Google, Microsoft, GitHub, etc.) and allows users to link multiple OAuth accounts to a single user profile. This document explains the design rationale and use cases.

## 🏗️ **Database Design Approach**

### **Two Design Options Considered:**

#### **Option 1: Simple (Users Table Only)**
```sql
-- Add OAuth fields directly to users table
ALTER TABLE users ADD COLUMN provider_name VARCHAR(50);
ALTER TABLE users ADD COLUMN provider_user_id VARCHAR(255);
ALTER TABLE users ADD COLUMN provider_access_token TEXT;
```

**Pros:**
- Simple and straightforward
- Easy to understand and implement
- Less database complexity

**Cons:**
- Only one OAuth provider per user
- No support for account linking
- Limited flexibility for future requirements

#### **Option 2: Flexible (User_Providers Table) - CHOSEN**
```sql
-- Separate table for provider relationships
CREATE TABLE user_providers (
    user_id INTEGER REFERENCES users(id),
    provider_id INTEGER REFERENCES providers(id),
    provider_user_id VARCHAR(255),
    access_token TEXT,
    refresh_token TEXT,
    is_primary BOOLEAN DEFAULT false,
    -- ... other fields
);
```

**Pros:**
- Multiple OAuth providers per user
- Support for account linking and merging
- Enterprise-ready with SSO flexibility
- Future-proof design
- Better user experience

**Cons:**
- More complex database schema
- Requires more careful implementation
- Additional table to manage

## 🔗 **Why User_Providers Table Exists**

### **Primary Purpose:**
The `user_providers` table exists to support **multiple OAuth providers per user**, enabling scenarios where a single user can authenticate through different OAuth providers while maintaining one unified user profile.

### **Key Benefits:**

1. **Account Linking**: Users can link multiple OAuth accounts to their profile
2. **Account Recovery**: Backup authentication methods if primary is compromised
3. **Enterprise Flexibility**: Support for multiple SSO providers
4. **Social Integration**: Different providers for different features
5. **Migration Support**: Easy to add new providers without schema changes

## 📊 **Table Structure & Field Purposes**

### **`providers` Table**
Stores OAuth provider configurations and settings.

| Field | Purpose | Example |
|-------|---------|---------|
| `name` | Provider identifier | 'google', 'microsoft', 'github' |
| `display_name` | Human-readable name | 'Google', 'Microsoft', 'GitHub' |
| `client_id` | OAuth client ID | '123456789.apps.googleusercontent.com' |
| `client_secret` | OAuth client secret (encrypted) | Encrypted secret |
| `authorization_url` | OAuth authorization endpoint | 'https://accounts.google.com/o/oauth2/v2/auth' |
| `token_url` | OAuth token endpoint | 'https://oauth2.googleapis.com/token' |
| `userinfo_url` | User profile endpoint | 'https://www.googleapis.com/oauth2/v2/userinfo' |
| `scopes` | Required OAuth scopes | 'openid email profile' |
| `is_enabled` | Whether provider is active | true/false |

### **`user_providers` Table**
Manages user-provider relationships and OAuth tokens.

| Field | Purpose | Example |
|-------|---------|---------|
| `user_id` | Links to main user account | User ID 123 |
| `provider_id` | References the OAuth provider | Google (ID 1) |
| `provider_user_id` | User's ID from OAuth provider | 'google_user_456' |
| `access_token` | OAuth access token (encrypted) | 'ya29.a0AfH6SMC...' |
| `refresh_token` | OAuth refresh token (encrypted) | '1//04dX...' |
| `token_type` | Token type | 'Bearer' |
| `expires_at` | Token expiration time | '2024-01-15 10:30:00' |
| `profile_data` | User info from provider | `{"name": "John", "email": "john@gmail.com"}` |
| `is_primary` | Main login method | true for primary, false for secondary |
| `is_active` | Whether this provider link is active | true/false |
| `last_used_at` | Last successful login time | '2024-01-10 15:45:00' |

### **Enhanced `users` Table**
Core user data with OAuth authentication method tracking.

| Field | Purpose | Example |
|-------|---------|---------|
| `auth_method` | Authentication method | 'password', 'oauth', 'both' |
| `primary_provider_id` | Primary OAuth provider | References providers.id |

## 🎭 **Real-World Use Cases**

### **1. Account Linking & Merging**
```
Scenario: "I signed up with Google, but my company uses Microsoft"

User Journey:
1. User signs up with Google account
   - Creates user record (ID: 123)
   - Creates user_providers record (Google, is_primary: true)

2. User joins company that uses Microsoft SSO
   - Links Microsoft account to existing profile
   - Creates another user_providers record (Microsoft, is_primary: false)

3. User can now login with either:
   - Google OAuth → finds user_providers record with Google
   - Microsoft OAuth → finds user_providers record with Microsoft

4. Both accounts point to same user profile and data
```

### **2. Social Media Integration**
```
Scenario: "I want to share content on multiple platforms"

User Journey:
1. User has Google account for general login
2. Links GitHub for developer features
3. Links LinkedIn for professional networking
4. Each provider gives access to different features:
   - Google: General app access
   - GitHub: Code repository integration
   - LinkedIn: Professional networking features
```

### **3. Enterprise Multi-Provider SSO**
```
Scenario: "I work for multiple companies with different SSO"

User Journey:
1. Personal Google account for general access
2. Company A Microsoft account for work projects
3. Company B GitHub account for open source work
4. All linked to same user profile
5. Can access different features based on which provider used
```

### **4. Account Recovery & Backup**
```
Scenario: "I lost access to my primary login"

User Journey:
1. Primary: Google account (is_primary: true)
2. Backup: Microsoft account (is_primary: false)
3. If Google account is compromised:
   - Can still access via Microsoft
   - Can reset Google account using Microsoft as verification
   - Maintains access to all user data
```

### **5. Gradual Migration**
```
Scenario: "Company is migrating from Google to Microsoft SSO"

User Journey:
1. Initially: All users have Google accounts
2. Migration period: Users link Microsoft accounts
3. Both providers active during transition
4. Eventually: Microsoft becomes primary, Google becomes backup
5. Smooth transition without data loss
```

## 🔄 **Data Flow Examples**

### **OAuth Login Flow**
```
1. User initiates OAuth login with Google
2. Redirect to Google's authorization URL
3. User authorizes application
4. Exchange authorization code for tokens
5. Fetch user profile from Google
6. Check if user exists:
   - If exists: Update user_providers record
   - If new: Create user and user_providers records
7. Create session record
8. Log successful login
9. Return access and refresh tokens
```

### **Account Linking Flow**
```
1. User is already logged in (e.g., via Google)
2. User initiates "Link Account" with Microsoft
3. OAuth flow with Microsoft
4. Create new user_providers record:
   - user_id: existing user ID
   - provider_id: Microsoft
   - is_primary: false (Google remains primary)
5. Store Microsoft tokens and profile data
6. User can now login with either provider
```

### **Token Refresh Flow**
```
1. Access token expires
2. Use refresh token from user_providers table
3. Exchange refresh token for new access token
4. Update user_providers record with new tokens
5. Update last_used_at timestamp
6. Log token refresh event
```

## 🏢 **Enterprise Considerations**

### **Multi-Tenant SSO**
- Different companies may use different SSO providers
- Users may work for multiple companies
- Need to support multiple provider configurations
- Role-based access based on provider

### **Security & Compliance**
- Audit trail for all OAuth logins
- Token encryption and secure storage
- Provider-specific security policies
- Compliance with enterprise security requirements

### **User Experience**
- Seamless switching between providers
- Consistent user profile across providers
- Graceful handling of provider outages
- Clear indication of linked accounts

## 🔧 **Implementation Guidelines**

### **Provider Management**
- Enable/disable providers via `providers.is_enabled`
- Configure provider-specific settings in `providers.config`
- Handle provider-specific OAuth flows
- Implement provider-specific error handling

### **Token Management**
- Encrypt all OAuth tokens before storage
- Implement automatic token refresh
- Handle token expiration gracefully
- Secure token transmission and storage

### **User Experience**
- Clear UI for account linking
- Indication of primary vs secondary providers
- Easy provider switching
- Account unlinking with proper cleanup

### **Security**
- Validate OAuth state parameters
- Implement CSRF protection
- Secure token storage and transmission
- Regular security audits

## 📈 **Future Considerations**

### **Scalability**
- Support for additional OAuth providers
- Performance optimization for multiple providers
- Caching strategies for provider data
- Load balancing for OAuth endpoints

### **Features**
- Provider-specific user attributes
- Custom OAuth scopes per provider
- Provider-specific authentication flows
- Advanced account linking scenarios

### **Integration**
- Webhook support for provider events
- Real-time provider status monitoring
- Provider-specific API integrations
- Custom provider implementations

## 🎯 **Summary**

The `user_providers` table design was chosen to provide maximum flexibility and support real-world scenarios where users need multiple OAuth providers. While it adds complexity, it enables:

- **Account linking and merging**
- **Enterprise SSO flexibility**
- **Account recovery options**
- **Social media integration**
- **Future-proof architecture**

This design supports both simple single-provider scenarios and complex multi-provider enterprise environments, making it suitable for a wide range of applications and use cases.
