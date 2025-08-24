package handlers

import (
	"github.com/your-project/services/auth/internal/business"
)

// AuthHandler handles gRPC requests for authentication
type AuthHandler struct {
	authBusiness *business.AuthBusiness
}

// NewAuthHandler creates a new auth handler instance
func NewAuthHandler(authBusiness *business.AuthBusiness) *AuthHandler {
	return &AuthHandler{
		authBusiness: authBusiness,
	}
}

// TODO: Implement gRPC service methods
// Examples:
// - Register
// - Login
// - ValidateToken
// - RefreshToken
// - Logout
