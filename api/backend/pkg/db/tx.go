package db

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/google/uuid"

	"github.com/uptrace/bun"
)

type Tx struct {
	bun.Tx
}

func (db *DB) NewTx(ctx context.Context, opts *sql.TxOptions) (Tx, error) {
	tx, err := db.BeginTx(ctx, opts)
	if err != nil {
		return Tx{}, fmt.Errorf("failed to begin transaction: %w", err)
	}

	return Tx{
		Tx: tx,
	}, nil
}

func (tx *Tx) SetUser(uid uuid.UUID) error {
	_, err := tx.Exec("set local role = 'authenticated';\nset local request.jwt.claim.sub = ?;", uid.String())
	return err
}

func (tx *Tx) UnsetUser() error {
	_, err := tx.Exec("set local role = 'postgres';\nset local request.jwt.claim.sub = '';")
	return err
}
