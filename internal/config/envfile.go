package config

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"gopkg.in/yaml.v3"
)

// parseUint converts string to uint
func parseUint(s string) (uint, error) {
	val, err := strconv.ParseUint(strings.TrimSpace(s), 10, 32)
	if err != nil {
		return 0, err
	}
	return uint(val), nil
}

// parseBool converts string to boolean
func parseBool(s string) bool {
	s = strings.ToLower(strings.TrimSpace(s))
	return s == "true" || s == "1" || s == "yes" || s == "on"
}

// LoadFromFile determines the env file type and passes to appropriate function
func LoadFromFile(path string, cfg *Config) error {
	ext := strings.ToLower(filepath.Ext(path))
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer func() { _ = file.Close() }()
	switch ext {
	case ".env":
		return readEnvFile(file, cfg)
	case ".yaml", ".yml":
		return readYamlFile(file, cfg)
	case ".json":
		return readJsonFile(file, cfg)
	default:
		return fmt.Errorf("unsupported file extension: %s", ext)
	}
}

// readEnvFile reads from .env file and loads configuration
func readEnvFile(file io.Reader, cfg *Config) error {
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}

		key := strings.TrimSpace(parts[0])
		// remove trailing comment, if present
		value := strings.SplitN(parts[1], "#", 2)[0]
		// remove leading/trailing whitespace
		value = strings.TrimSpace(value)
		// Remove quotes if present
		value = strings.Trim(value, `"'`)

		// Map environment variables to config fields
		switch key {
		case "PORT":
			if port, err := parseUint(value); err == nil {
				cfg.Port = port
			}
		case "USE_TLS":
			cfg.UseTLS = parseBool(value)
		case "DEBUG_MODE":
			cfg.DebugMode = parseBool(value)
		case "LOG_LEVEL":
			cfg.LogLevel = value
		}
	}

	return scanner.Err()
}

// readYamlFile reads from .yaml file
func readYamlFile(file io.Reader, cfg *Config) error {
	decoder := yaml.NewDecoder(file)
	if err := decoder.Decode(cfg); err != nil {
		return fmt.Errorf("failed to decode YAML: %w", err)
	}
	return nil
}

// readJsonFile reads from .json file
func readJsonFile(file io.Reader, cfg *Config) error {
	decoder := json.NewDecoder(file)
	if err := decoder.Decode(cfg); err != nil {
		return fmt.Errorf("failed to decode JSON: %w", err)
	}
	return nil
}
