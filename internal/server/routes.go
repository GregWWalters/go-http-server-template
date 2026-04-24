package server

import (
	"github.com/OWNER/PROJECT-NAME/internal/handlers"
	"github.com/go-chi/chi/v5"
)

// RegisterRoutes configures all application routes
func (s *Server) RegisterRoutes() {
	// Health check endpoint
	s.router.Get("/health", handlers.Health())

	// API routes
	// TODO: Add your application-specific routes here
	s.router.Route("/api", func(r chi.Router) {
		// Example routes - replace with your actual endpoints
		r.Get("/example", handlers.ExampleList())
		r.Post("/example", handlers.ExampleCreate())
		r.Get("/example/{id}", handlers.ExampleGet())
	})
}
