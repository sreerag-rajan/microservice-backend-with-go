package jwt

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// JWTManager handles generic JWT token operations
type JWTManager struct {
	secretKey []byte
}

// NewJWTManager creates a new JWT manager instance
func NewJWTManager(secretKey string) *JWTManager {
	return &JWTManager{
		secretKey: []byte(secretKey),
	}
}

// GenerateToken generates a JWT token with the provided claims
func (j *JWTManager) GenerateToken(claims jwt.Claims) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(j.secretKey)
}

// GenerateTokenWithExpiry generates a JWT token with custom expiry
func (j *JWTManager) GenerateTokenWithExpiry(claims jwt.Claims, expiry time.Duration) (string, error) {
	// If claims implement CustomClaims interface, set expiry
	if customClaims, ok := claims.(CustomClaims); ok {
		customClaims.SetExpiry(expiry)
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(j.secretKey)
}

// ParseToken parses a JWT token and returns the claims
func (j *JWTManager) ParseToken(tokenString string, claims jwt.Claims) error {
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		// Validate the signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return j.secretKey, nil
	})

	if err != nil {
		return fmt.Errorf("failed to parse token: %w", err)
	}

	if !token.Valid {
		return fmt.Errorf("invalid token")
	}

	return nil
}

// ParseTokenWithoutValidation parses a token without validating expiry
// Useful for extracting information from expired tokens
func (j *JWTManager) ParseTokenWithoutValidation(tokenString string, claims jwt.Claims) error {
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return j.secretKey, nil
	})

	if err != nil {
		return fmt.Errorf("failed to parse token: %w", err)
	}

	if !token.Valid {
		return fmt.Errorf("invalid token signature")
	}

	return nil
}

// IsTokenExpired checks if a token is expired
func (j *JWTManager) IsTokenExpired(tokenString string, claims jwt.Claims) (bool, error) {
	// Try to parse the token normally first
	err := j.ParseToken(tokenString, claims)
	if err == nil {
		// Token is valid and not expired
		return false, nil
	}

	// If parsing failed, try to extract claims without validation
	token, parseErr := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return j.secretKey, nil
	})

	if parseErr != nil {
		return true, parseErr
	}

	// Check if claims implement expiry checking
	expTime, err := token.Claims.GetExpirationTime()
	if err == nil && expTime != nil && expTime.Time.Before(time.Now()) {
		return true, nil
	}

	return false, nil
}

// GetTokenExpiration returns the expiration time of a token
func (j *JWTManager) GetTokenExpiration(tokenString string, claims jwt.Claims) (time.Time, error) {
	err := j.ParseToken(tokenString, claims)
	if err != nil {
		return time.Time{}, err
	}

	expTime, err := claims.GetExpirationTime()
	if err == nil && expTime != nil {
		return expTime.Time, nil
	}

	return time.Time{}, fmt.Errorf("token has no expiration time")
}

// CustomClaims interface for claims that can set custom expiry
type CustomClaims interface {
	jwt.Claims
	SetExpiry(expiry time.Duration)
}

// BaseClaims provides a basic implementation of jwt.Claims
// Services can embed this in their own claims structures
type BaseClaims struct {
	ExpiresAt *jwt.NumericDate `json:"exp,omitempty"`
	IssuedAt  *jwt.NumericDate `json:"iat,omitempty"`
	NotBefore *jwt.NumericDate `json:"nbf,omitempty"`
	Issuer    string           `json:"iss,omitempty"`
	Subject   string           `json:"sub,omitempty"`
	Audience  jwt.ClaimStrings `json:"aud,omitempty"`
	ID        string           `json:"jti,omitempty"`
}

// GetExpirationTime returns the expiration time
func (b *BaseClaims) GetExpirationTime() (*jwt.NumericDate, error) {
	return b.ExpiresAt, nil
}

// GetNotBefore returns the not before time
func (b *BaseClaims) GetNotBefore() (*jwt.NumericDate, error) {
	return b.NotBefore, nil
}

// GetIssuedAt returns the issued at time
func (b *BaseClaims) GetIssuedAt() (*jwt.NumericDate, error) {
	return b.IssuedAt, nil
}

// GetIssuer returns the issuer
func (b *BaseClaims) GetIssuer() (string, error) {
	return b.Issuer, nil
}

// GetSubject returns the subject
func (b *BaseClaims) GetSubject() (string, error) {
	return b.Subject, nil
}

// GetAudience returns the audience
func (b *BaseClaims) GetAudience() (jwt.ClaimStrings, error) {
	return b.Audience, nil
}

// GetID returns the ID
func (b *BaseClaims) GetID() (string, error) {
	return b.ID, nil
}

// SetExpiry sets the token expiration time
func (b *BaseClaims) SetExpiry(expiry time.Duration) {
	b.ExpiresAt = jwt.NewNumericDate(time.Now().Add(expiry))
}

// SetIssuedAt sets the token issued at time
func (b *BaseClaims) SetIssuedAt(issuedAt time.Time) {
	b.IssuedAt = jwt.NewNumericDate(issuedAt)
}

// SetNotBefore sets the token not before time
func (b *BaseClaims) SetNotBefore(notBefore time.Time) {
	b.NotBefore = jwt.NewNumericDate(notBefore)
}

// SetIssuer sets the token issuer
func (b *BaseClaims) SetIssuer(issuer string) {
	b.Issuer = issuer
}

// SetSubject sets the token subject
func (b *BaseClaims) SetSubject(subject string) {
	b.Subject = subject
}

// SetAudience sets the token audience
func (b *BaseClaims) SetAudience(audience []string) {
	b.Audience = audience
}

// SetID sets the token ID
func (b *BaseClaims) SetID(id string) {
	b.ID = id
}
