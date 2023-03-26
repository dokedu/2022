package db

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"github.com/uptrace/bun"
	"github.com/uptrace/bun/dialect/pgdialect"
	"github.com/uptrace/bun/driver/pgdriver"
	"github.com/uptrace/bun/extra/bundebug"
)

var dbModels = []interface{}{&models.Account{}, &models.Organisation{}, &models.Identity{}, &models.Account{}, &models.EntryAccount{}, &models.EntryAccountCompetence{}}

type SSLMode string

const (
	SslModeDisable SSLMode = "disable"
	SslModePrefer  SSLMode = "prefer"
)

type DB struct {
	*bun.DB
}

type Config struct {
	Username string
	Password string
	Host     string
	Port     string
	Database string
	SSLMode  SSLMode
}

// New returns a new database instance with the given configuration
func New(cfg Config) (*DB, error) {
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s", cfg.Username, cfg.Password, cfg.Host, cfg.Port, cfg.Database, cfg.SSLMode)
	sqldb := sql.OpenDB(pgdriver.NewConnector(pgdriver.WithDSN(dsn)))

	// check if we can connect
	if err := sqldb.Ping(); err != nil {
		return nil, fmt.Errorf("could not establish a connection: %w", err)
	}

	db := bun.NewDB(sqldb, pgdialect.New())
	db.RegisterModel(dbModels...)
	db.AddQueryHook(bundebug.NewQueryHook(bundebug.WithVerbose(true)))

	err := pgdriver.Notify(context.Background(), db, "pgrst", "reload schema")
	if err != nil {
		return nil, err
	}

	return &DB{
		db,
	}, nil
}
