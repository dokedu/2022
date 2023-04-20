package db

import (
	"database/sql"
	"example/graph/model"
	"fmt"
	"github.com/uptrace/bun"
	"github.com/uptrace/bun/dialect/pgdialect"
	"github.com/uptrace/bun/driver/pgdriver"
	"github.com/uptrace/bun/extra/bundebug"
)

var models = []interface{}{&model.User{}}

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

func New(config Config) (*DB, error) {
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s", config.Username, config.Password, config.Host, config.Port, config.Database, config.SSLMode)
	conn := sql.OpenDB(pgdriver.NewConnector(pgdriver.WithDSN(dsn)))

	// check if we can connect
	if err := conn.Ping(); err != nil {
		return nil, fmt.Errorf("could not establish a connection: %w", err)
	}

	db := bun.NewDB(conn, pgdialect.New())
	db.RegisterModel(models...)
	db.AddQueryHook(bundebug.NewQueryHook(bundebug.WithVerbose(true)))

	return &DB{
		db,
	}, nil

}
