package db_test

import (
	"github.com/dokedu/dokedu-api-beta/services/pkg/config"
	"github.com/dokedu/dokedu-api-beta/services/pkg/db"
	"testing"
)

func TestNew(t *testing.T) {
	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("error loading config: %v", err)
	}

	db, err := db.New(cfg.DBConfig)
	if err != nil {
		t.Fatal(err)
	}

	// db should be non-nil
	if db == nil {
		t.Fatal("expected non-nil db instance")
	}
}
