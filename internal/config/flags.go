package config

import (
	"flag"
)

// TODO: replace specific flag definitions with a function for generating
// them from the Config's struct tags

// DefineFlags defines command-line flags based on the Config struct
func DefineFlags(defaults, dest *Config) {
	// Server
	flag.UintVar(&dest.Port, "port", defaults.Port, "Set port")
	flag.BoolVar(&dest.UseTLS, "use-tls", defaults.UseTLS, "Enable TLS")

	// Debug
	flag.BoolVar(&dest.DebugMode, "debug-mode", defaults.DebugMode, "Enable debug mode")
	flag.StringVar(&dest.LogLevel, "log-level", defaults.LogLevel, "Set log level")
}
