package tests

import (
	"os"
	"testing"

	"github.com/your-project/services/auth/internal/config"
)

func TestLoad(t *testing.T) {
	// Test with default values
	os.Unsetenv("PORT")
	os.Unsetenv("DB_CONNECTION_URL")
	os.Unsetenv("MAX_CONNECTION_POOL")

	_, err := config.Load()
	if err == nil {
		t.Error("Expected error when DB_CONNECTION_URL is not set")
	}

	// Test with valid values
	os.Setenv("DB_CONNECTION_URL", "postgres://test:test@localhost:5432/test")
	os.Setenv("PORT", "50052")
	os.Setenv("MAX_CONNECTION_POOL", "20")

	cfg, err := config.Load()
	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	}

	if cfg.Port != "50052" {
		t.Errorf("Expected port 50052, got %s", cfg.Port)
	}

	if cfg.DBConnectionURL != "postgres://test:test@localhost:5432/test" {
		t.Errorf("Expected DB connection URL, got %s", cfg.DBConnectionURL)
	}

	if cfg.MaxConnectionPool != 20 {
		t.Errorf("Expected max connection pool 20, got %d", cfg.MaxConnectionPool)
	}
}

func TestGetEnv(t *testing.T) {
	// Test with existing environment variable
	os.Setenv("TEST_VAR", "test_value")
	result := config.GetEnv("TEST_VAR", "default")
	if result != "test_value" {
		t.Errorf("Expected test_value, got %s", result)
	}

	// Test with non-existing environment variable
	result = config.GetEnv("NON_EXISTENT", "default_value")
	if result != "default_value" {
		t.Errorf("Expected default_value, got %s", result)
	}
}
