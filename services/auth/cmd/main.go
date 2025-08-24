package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"github.com/your-project/services/auth/internal/business"
	"github.com/your-project/services/auth/internal/config"
	"github.com/your-project/services/auth/internal/handlers"
	"github.com/your-project/services/auth/internal/repository"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize database connection
	db, err := config.NewDatabaseConnection(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Initialize repository layer
	authRepo := repository.NewAuthRepository(db)

	// Initialize business logic layer
	authBusiness := business.NewAuthBusiness(authRepo)

	// Initialize gRPC handlers
	_ = handlers.NewAuthHandler(authBusiness)

	// Create gRPC server
	grpcServer := grpc.NewServer()

	// Register services
	// TODO: Register your auth service here
	// authpb.RegisterAuthServiceServer(grpcServer, authHandler)

	// Enable reflection for development
	reflection.Register(grpcServer)

	// Create listener
	lis, err := net.Listen("tcp", fmt.Sprintf(":%s", cfg.Port))
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Starting auth service on port %s", cfg.Port)
		if err := grpcServer.Serve(lis); err != nil {
			log.Fatalf("Failed to serve: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down auth service...")

	// Graceful shutdown
	_, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	grpcServer.GracefulStop()

	log.Println("Auth service stopped gracefully")
}
