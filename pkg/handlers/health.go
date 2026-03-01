package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/OWNER/PROJECT-NAME/internal/constants"
)

// HealthResponse represents the health check response
type HealthResponse struct {
	Status   string `json:"status"`
	Version  string `json:"version,omitempty"`
	Revision string `json:"revision,omitempty"`
}

// Health returns a basic health check handler
func Health() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		response := HealthResponse{
			Status:   "ok",
			Version:  constants.AppVersion,
			Revision: constants.AppVCSRevision,
		}

		if err := json.NewEncoder(w).Encode(response); err != nil {
			http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		}
	}
}
