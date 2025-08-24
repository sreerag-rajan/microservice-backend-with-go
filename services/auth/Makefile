.PHONY: build test run clean

# Build the auth service
build:
	go build -o bin/auth-service cmd/main.go

# Run tests
test:
	go test ./tests/...

# Run all tests (including internal tests)
test-all:
	go test ./...

# Run the service
run:
	go run cmd/main.go

# Clean build artifacts
clean:
	rm -rf bin/

# Install dependencies
deps:
	go mod tidy
	go mod download

# Build and run
dev: build
	./bin/auth-service
