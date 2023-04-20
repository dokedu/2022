package config

import (
	_ "embed"
	"example/pkg/db"
	"fmt"
	"github.com/joho/godotenv"
	"os"
)

type Config struct {
	DBConfig db.Config
}

func Load() (*Config, error) {
	env := os.Getenv("GO_ENV")
	prefix := ""
	suffix := ""

	if env == "test" {
		suffix = ".test"
	}

	var err error
	for i := 0; i < 5; i++ {
		err = godotenv.Load(fmt.Sprintf("%s.env%s", prefix, suffix))
		if err == nil {
			break
		} else {
			prefix += "../"
		}
	}
	if err != nil {
		return nil, fmt.Errorf("could not load environment file %w", err)
	}

	env = os.Getenv("GO_ENV")

	var sslMode db.SSLMode
	if os.Getenv("DB_SSL") == "true" {
		sslMode = db.SslModePrefer
	} else {
		sslMode = db.SslModeDisable
	}

	cfg := &Config{
		DBConfig: db.Config{
			Username: os.Getenv("DB_USER"),
			Password: os.Getenv("DB_PASS"),
			Host:     os.Getenv("DB_HOST"),
			Port:     os.Getenv("DB_PORT"),
			Database: os.Getenv("DB_NAME"),
			SSLMode:  sslMode,
		},
	}

	return cfg, nil
}
