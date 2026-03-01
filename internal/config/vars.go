package config

type Config struct {
	// environment file path
	envFile string

	// Server
	UseTLS bool `env:"USE_TLS" yaml:"use_tls" json:"use_tls" flag:"use-tls"`
	Port   uint `env:"PORT" yaml:"port" json:"port" flag:"port"`

	// Debug
	DebugMode bool   `env:"DEBUG_MODE" yaml:"debug_mode" json:"debug_mode" flag:"debug-mode"`
	LogLevel  string `env:"LOG_LEVEL" yaml:"log_level" json:"log_level" flag:"log-level"`
}

var defaults Config = Config{
	// Server
	UseTLS: false,
	Port:   8080,

	// Debug
	DebugMode: false,
	LogLevel:  "INFO",
}
