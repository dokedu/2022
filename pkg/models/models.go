package models

import (
	"database/sql"
	"github.com/uptrace/bun"
	"time"
)

type UserRole string

type User struct {
	bun.BaseModel

	ID             string `bun:",nullzero,pk"`
	Role           UserRole
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`
	FirstName      string
	LastName       string
	CreatedAt      time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt      sql.NullTime `bun:",soft_delete,nullzero"`
}

type Organisation struct {
	bun.BaseModel

	ID        string `bun:",nullzero,pk"`
	Name      string
	OwnerID   string
	Owner     *User        `bun:"-,rel:belongs-to"`
	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}

type Entry struct {
	bun.BaseModel

	ID        string `bun:",nullzero,pk"`
	Date      time.Time
	Body      string
	UserID    string
	User      *User        `bun:"-,rel:belongs-to"`
	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}
