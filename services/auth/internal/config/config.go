package config

import (
	"database/sql"
	"fmt"
	"os"
	"strconv"
	"time"

	_ "github.com/lib/pq"
)

// Config holds all configuration for the auth service
type Config struct {
	Port              string
	DBConnectionURL   string
	MaxConnectionPool int
}

// Load loads configuration from environment variables
func Load() (*Config, error) {
	port := GetEnv("PORT", "50051")
	dbConnectionURL := GetEnv("DB_CONNECTION_URL", "")
	maxConnectionPoolStr := GetEnv("MAX_CONNECTION_POOL", "10")

	maxConnectionPool, err := strconv.Atoi(maxConnectionPoolStr)
	if err != nil {
		return nil, fmt.Errorf("invalid MAX_CONNECTION_POOL value: %v", err)
	}

	if dbConnectionURL == "" {
		return nil, fmt.Errorf("DB_CONNECTION_URL environment variable is required")
	}

	return &Config{
		Port:              port,
		DBConnectionURL:   dbConnectionURL,
		MaxConnectionPool: maxConnectionPool,
	}, nil
}

// NewDatabaseConnection creates a new database connection with connection pooling
func NewDatabaseConnection(cfg *Config) (*sql.DB, error) {
	db, err := sql.Open("postgres", cfg.DBConnectionURL)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %v", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(cfg.MaxConnectionPool)
	db.SetMaxIdleConns(cfg.MaxConnectionPool / 2)
	db.SetConnMaxLifetime(time.Hour)

	// Test the connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %v", err)
	}

	return db, nil
}

// GetEnv gets an environment variable with a fallback default value
// Made public for testing purposes
func GetEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
