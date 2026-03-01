package server

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/OWNER/PROJECT-NAME/internal/config"
	"github.com/OWNER/PROJECT-NAME/pkg/middleware"
	"github.com/gorilla/mux"
)

// Server represents an HTTP server instance
type Server struct {
	httpServer *http.Server
	router     *mux.Router
	config     config.Config
}

// New creates a new Server instance
func New(cfg config.Config) *Server {
	router := mux.NewRouter()

	return &Server{
		router: router,
		config: cfg,
	}
}

// Router returns the server's router for route registration
func (s *Server) Router() *mux.Router {
	return s.router
}

// Start starts the HTTP server
func (s *Server) Start() error {
	// Apply global middleware
	handler := middleware.Recovery(s.router)
	handler = middleware.Logging(handler)
	handler = middleware.CORS(handler)

	addr := fmt.Sprintf(":%d", s.config.Port)

	s.httpServer = &http.Server{
		Addr:         addr,
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	if s.config.UseTLS {
		// TODO: Configure TLS certificates
		log.Printf("Starting HTTPS server on %s", addr)
		return s.httpServer.ListenAndServeTLS("cert.pem", "key.pem")
	}

	log.Printf("Starting HTTP server on %s", addr)
	return s.httpServer.ListenAndServe()
}

// Shutdown gracefully shuts down the server
func (s *Server) Shutdown(ctx context.Context) error {
	if s.httpServer != nil {
		return s.httpServer.Shutdown(ctx)
	}
	return nil
}
