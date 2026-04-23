package server

import (
	handlers2 "github.com/OWNER/PROJECT-NAME/internal/handlers"
	"github.com/go-chi/chi/v5"
)

// RegisterRoutes configures all application routes
func (s *Server) RegisterRoutes() {
	// Health check endpoint
	s.router.Get("/health", handlers2.Health())

	// API routes
	// TODO: Add your application-specific routes here
	s.router.Route("/api", func(r chi.Router) {
		// Example routes - replace with your actual endpoints
		r.Get("/example", handlers2.ExampleList())
		r.Post("/example", handlers2.ExampleCreate())
		r.Get("/example/{id}", handlers2.ExampleGet())
	})
}
