package config

import (
	"flag"
	"os"
)

// Load loads configuration from environment file, environment variables, and command-line flags
// Precedence: command-line flags > environment variables > environment file > defaults
func Load() (Config, error) {
	cfg := defaults

	// Check for environment file flag
	var envFile string
	flag.StringVar(&envFile, "env-file", "", "Load environment variables from file")

	// Parse flags first to get env-file
	flag.Parse()

	// Load from environment file if specified
	if envFile != "" {
		if err := LoadFromFile(envFile, &cfg); err != nil {
			return cfg, err
		}
	}

	// Load from environment variables
	LoadFromEnv(&cfg)

	// Apply command-line flags (highest precedence)
	DefineFlags(&defaults, &cfg)

	return cfg, nil
}

// LoadFromEnv loads configuration from environment variables
func LoadFromEnv(cfg *Config) {
	if val := os.Getenv("PORT"); val != "" {
		if port, err := parseUint(val); err == nil {
			cfg.Port = port
		}
	}

	if val := os.Getenv("USE_TLS"); val != "" {
		cfg.UseTLS = parseBool(val)
	}

	if val := os.Getenv("DEBUG_MODE"); val != "" {
		cfg.DebugMode = parseBool(val)
	}

	if val := os.Getenv("LOG_LEVEL"); val != "" {
		cfg.LogLevel = val
	}
}
