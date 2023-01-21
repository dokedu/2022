package db_test

import (
	"context"
	"github.com/dokedu/dokedu-api-beta/services/pkg/db"
	"testing"

	"github.com/dokedu/dokedu-api-beta/services/pkg/config"
)

func TestNewTx(t *testing.T) {
	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("error loading config: %v", err)
	}

	iDb, err := db.New(cfg.DBConfig)
	if err != nil {
		t.Fatal(err)
	}

	ctx := context.Background()
	_, err = iDb.NewTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
}
