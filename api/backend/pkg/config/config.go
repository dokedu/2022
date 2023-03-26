package config

import (
	_ "embed"
	"fmt"
	"github.com/dokedu/dokedu-api-beta/services/pkg/api"
	"github.com/dokedu/dokedu-api-beta/services/pkg/db"
	"github.com/dokedu/dokedu-api-beta/services/pkg/modules"
	"github.com/joho/godotenv"
	log "github.com/sirupsen/logrus"
	"os"
	"path"
	"strings"
)

type Config struct {
	DBConfig       db.Config
	MeiliConfig    modules.MeiliSearchConfig
	ApiConfig      api.Config
	SupabaseConfig modules.SupabaseModuleConfig
	PrinterConfig  modules.PrinterConfig

	BaseDir string
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

	baseDir := path.Join(prefix)
	env = os.Getenv("GO_ENV")

	var sslMode db.SSLMode
	if os.Getenv("DB_SSL") == "true" {
		sslMode = db.SslModePrefer
	} else {
		sslMode = db.SslModeDisable
	}

	var apiEnv api.ApiEnvironment
	if env == "test" || env == "development" {
		apiEnv = api.ApiEnvironmentDevelopment
	} else if env == "production" {
		apiEnv = api.ApiEnvironmentProduction
	} else {
		log.Fatalf("unknown environment %s", env)
	}

	printerFolder := os.Getenv("PRINTER_FOLDER")
	if !path.IsAbs(printerFolder) {
		printerFolder = fmt.Sprintf("%s/%s", baseDir, printerFolder)
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
		MeiliConfig: modules.MeiliSearchConfig{
			BaseURL:   os.Getenv("MEILI_BASE_URL"),
			PublicKey: os.Getenv("MEILI_PUBLIC_KEY"),
		},
		ApiConfig: api.Config{
			Host:             os.Getenv("API_HOST"),
			Port:             os.Getenv("API_PORT"),
			JwtSecret:        os.Getenv("API_JWT_SECRET"),
			AllowedOrigins:   strings.Split(os.Getenv("API_CORS_ALLOWED_ORIGINS"), ","),
			Debug:            false,
			ValidateRequests: true,
			Environment:      apiEnv,
		},
		SupabaseConfig: modules.SupabaseModuleConfig{
			SupabaseBaseURL:        os.Getenv("SUPABASE_BASE_URL"),
			SupabaseServiceRoleKey: os.Getenv("SUPABASE_SERVICE_ROLE_KEY"),
		},
		PrinterConfig: modules.PrinterConfig{
			Folder:         printerFolder,
			RodURL:         os.Getenv("PRINTER_ROD_URL"),
			DocxExportPath: path.Join(baseDir, "docxExport"),
		},
	}

	return cfg, nil
}
