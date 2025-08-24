package tests

import (
	"database/sql"
	"os"
	"testing"

	"github.com/your-project/services/auth/internal/business"
	"github.com/your-project/services/auth/internal/config"
	"github.com/your-project/services/auth/internal/handlers"
	"github.com/your-project/services/auth/internal/repository"
)

// TestSetup provides a complete test setup with all layers
type TestSetup struct {
	Config   *config.Config
	DB       *sql.DB
	Repo     *repository.AuthRepository
	Business *business.AuthBusiness
	Handler  *handlers.AuthHandler
}

// SetupTestEnvironment creates a complete test environment
func SetupTestEnvironment(t *testing.T) *TestSetup {
	// Set test environment variables
	os.Setenv("DB_CONNECTION_URL", "postgres://test:test@localhost:5432/test_db?sslmode=disable")
	os.Setenv("PORT", "50051")
	os.Setenv("MAX_CONNECTION_POOL", "5")

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("Failed to load test configuration: %v", err)
	}

	// Create database connection (this will fail in tests without a real DB, but that's expected)
	db, err := config.NewDatabaseConnection(cfg)
	if err != nil {
		// For unit tests, we'll use a nil DB since we don't have a real database
		db = nil
	}

	// Create all layers
	repo := repository.NewAuthRepository(db)
	business := business.NewAuthBusiness(repo)
	handler := handlers.NewAuthHandler(business)

	return &TestSetup{
		Config:   cfg,
		DB:       db,
		Repo:     repo,
		Business: business,
		Handler:  handler,
	}
}

// CleanupTestEnvironment cleans up test environment
func CleanupTestEnvironment(t *testing.T, setup *TestSetup) {
	if setup.DB != nil {
		setup.DB.Close()
	}

	// Unset environment variables
	os.Unsetenv("DB_CONNECTION_URL")
	os.Unsetenv("PORT")
	os.Unsetenv("MAX_CONNECTION_POOL")
}

// MockDB returns a mock database connection for testing
func MockDB() *sql.DB {
	// Return nil for now - in real tests you might want to use a test database
	// or a mock implementation
	return nil
}
