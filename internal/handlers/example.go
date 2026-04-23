package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
)

// ExampleResponse represents a simple JSON response
type ExampleResponse struct {
	Message string `json:"message"`
	ID      string `json:"id,omitempty"`
}

// ExampleList handles GET /api/example
// TODO: Replace with your actual handler logic
func ExampleList() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		response := ExampleResponse{
			Message: "This is an example list endpoint",
		}

		json.NewEncoder(w).Encode(response)
	}
}

// ExampleGet handles GET /api/example/{id}
// TODO: Replace with your actual handler logic
func ExampleGet() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		w.Header().Set("Content-Type", "application/json")

		response := ExampleResponse{
			Message: "This is an example get endpoint",
			ID:      id,
		}

		json.NewEncoder(w).Encode(response)
	}
}

// ExampleCreate handles POST /api/example
// TODO: Replace with your actual handler logic
func ExampleCreate() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req ExampleResponse
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid request body", http.StatusBadRequest)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)

		response := ExampleResponse{
			Message: "Resource created",
			ID:      "new-id",
		}

		json.NewEncoder(w).Encode(response)
	}
}
