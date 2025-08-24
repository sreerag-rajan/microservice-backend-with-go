package jwt

import (
	"testing"
	"time"
)

// TestClaims implements jwt.Claims for testing
type TestClaims struct {
	BaseClaims
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	Type   string `json:"type"`
}

func (t *TestClaims) SetExpiry(expiry time.Duration) {
	t.BaseClaims.SetExpiry(expiry)
}

func TestJWTManager_GenerateAndParseToken(t *testing.T) {
	secretKey := "test-secret-key"
	jwtManager := NewJWTManager(secretKey)

	// Create test claims
	claims := &TestClaims{
		UserID: "user123",
		Email:  "test@example.com",
		Type:   "access",
	}
	claims.SetExpiry(15 * time.Minute)
	claims.SetIssuer("test-service")
	claims.SetSubject("user123")

	// Generate token
	token, err := jwtManager.GenerateToken(claims)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}

	// Parse token
	parsedClaims := &TestClaims{}
	err = jwtManager.ParseToken(token, parsedClaims)
	if err != nil {
		t.Fatalf("Failed to parse token: %v", err)
	}

	// Verify claims
	if parsedClaims.UserID != "user123" {
		t.Errorf("Expected user ID %s, got %s", "user123", parsedClaims.UserID)
	}

	if parsedClaims.Email != "test@example.com" {
		t.Errorf("Expected email %s, got %s", "test@example.com", parsedClaims.Email)
	}

	if parsedClaims.Type != "access" {
		t.Errorf("Expected type %s, got %s", "access", parsedClaims.Type)
	}
}

func TestJWTManager_GenerateTokenWithExpiry(t *testing.T) {
	secretKey := "test-secret-key"
	jwtManager := NewJWTManager(secretKey)

	// Create test claims
	claims := &TestClaims{
		UserID: "user123",
		Email:  "test@example.com",
		Type:   "refresh",
	}
	claims.SetIssuer("test-service")

	// Generate token with custom expiry
	token, err := jwtManager.GenerateTokenWithExpiry(claims, 7*24*time.Hour)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}

	// Parse token
	parsedClaims := &TestClaims{}
	err = jwtManager.ParseToken(token, parsedClaims)
	if err != nil {
		t.Fatalf("Failed to parse token: %v", err)
	}

	// Verify expiry was set
	if parsedClaims.ExpiresAt == nil {
		t.Error("Expected expiry to be set")
	}
}

func TestJWTManager_InvalidToken(t *testing.T) {
	secretKey := "test-secret-key"
	jwtManager := NewJWTManager(secretKey)

	// Test invalid token
	claims := &TestClaims{}
	err := jwtManager.ParseToken("invalid-token", claims)
	if err == nil {
		t.Error("Expected error for invalid token, got nil")
	}
}

func TestJWTManager_TokenExpiry(t *testing.T) {
	secretKey := "test-secret-key"
	jwtManager := NewJWTManager(secretKey)

	// Create test claims with future expiry
	claims := &TestClaims{
		UserID: "user123",
		Email:  "test@example.com",
		Type:   "access",
	}
	claims.SetExpiry(1 * time.Hour) // Future expiry
	claims.SetIssuer("test-service")

	// Generate token
	token, err := jwtManager.GenerateToken(claims)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}

	// Check if token is expired (should not be)
	isExpired, err := jwtManager.IsTokenExpired(token, &TestClaims{})
	if err != nil {
		t.Fatalf("Failed to check token expiry: %v", err)
	}

	if isExpired {
		t.Error("Expected token to not be expired")
	}
}

func TestJWTManager_ParseTokenWithoutValidation(t *testing.T) {
	secretKey := "test-secret-key"
	jwtManager := NewJWTManager(secretKey)

	// Create test claims
	claims := &TestClaims{
		UserID: "user123",
		Email:  "test@example.com",
		Type:   "access",
	}
	claims.SetExpiry(1 * time.Hour) // Valid expiry
	claims.SetIssuer("test-service")

	// Generate token
	token, err := jwtManager.GenerateToken(claims)
	if err != nil {
		t.Fatalf("Failed to generate token: %v", err)
	}

	// Parse without validation (should succeed)
	parsedClaims := &TestClaims{}
	err = jwtManager.ParseTokenWithoutValidation(token, parsedClaims)
	if err != nil {
		t.Fatalf("Failed to parse token without validation: %v", err)
	}

	// Verify we can extract the claims
	if parsedClaims.UserID != "user123" {
		t.Errorf("Expected user ID %s, got %s", "user123", parsedClaims.UserID)
	}
}

func TestBaseClaims_Setters(t *testing.T) {
	claims := &BaseClaims{}

	// Test all setters
	now := time.Now()
	claims.SetExpiry(15 * time.Minute)
	claims.SetIssuedAt(now)
	claims.SetNotBefore(now)
	claims.SetIssuer("test-service")
	claims.SetSubject("user123")
	claims.SetAudience([]string{"api"})
	claims.SetID("token-123")

	// Verify values were set
	if claims.ExpiresAt == nil {
		t.Error("Expected ExpiresAt to be set")
	}

	if claims.IssuedAt == nil {
		t.Error("Expected IssuedAt to be set")
	}

	if claims.Issuer != "test-service" {
		t.Errorf("Expected issuer %s, got %s", "test-service", claims.Issuer)
	}

	if claims.Subject != "user123" {
		t.Errorf("Expected subject %s, got %s", "user123", claims.Subject)
	}

	if claims.ID != "token-123" {
		t.Errorf("Expected ID %s, got %s", "token-123", claims.ID)
	}
}
