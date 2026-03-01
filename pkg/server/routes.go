package server

import (
	"github.com/OWNER/PROJECT-NAME/pkg/handlers"
)

// RegisterRoutes configures all application routes
func (s *Server) RegisterRoutes() {
	// Health check endpoint
	s.router.HandleFunc("/health", handlers.Health()).Methods("GET")

	// API routes
	// TODO: Add your application-specific routes here
	api := s.router.PathPrefix("/api").Subrouter()

	// Example routes - replace with your actual endpoints
	api.HandleFunc("/example", handlers.ExampleList()).Methods("GET")
	api.HandleFunc("/example", handlers.ExampleCreate()).Methods("POST")
	api.HandleFunc("/example/{id}", handlers.ExampleGet()).Methods("GET")
}
