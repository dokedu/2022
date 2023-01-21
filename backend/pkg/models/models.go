package models

import (
	"database/sql"
	"github.com/google/uuid"
	"github.com/uptrace/bun"
	"time"
)

type Address struct {
	bun.BaseModel

	ID        string `bun:",nullzero,pk"`
	Street    string
	Zip       string
	City      string
	State     string
	Country   string
	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}

type Organisation struct {
	bun.BaseModel

	ID   string `bun:",nullzero,pk"`
	Name string

	AddressID string
	Address   *Address `bun:"-,rel:belongs-to"`

	LegalName string
	Website   string
	Phone     string
	OwnerID   string
	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}

type Identity struct {
	bun.BaseModel

	ID         string `bun:",nullzero,pk"`
	UserID     uuid.UUID
	GlobalRole string
	CreatedAt  time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt  sql.NullTime `bun:",soft_delete,nullzero"`
}

type Account struct {
	bun.BaseModel

	ID             string `bun:",nullzero,pk"`
	Role           string
	IdentityID     sql.NullString
	Identity       *Identity `bun:"-,rel:belongs-to"`
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`
	FirstName      string
	LastName       string
	CreatedAt      time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt      sql.NullTime `bun:",soft_delete,nullzero"`
}

type Competence struct {
	bun.BaseModel

	ID             string `bun:",nullzero,pk"`
	Name           string
	CompetenceID   sql.NullString
	Competence     *Competence `bun:"-,rel:belongs-to"`
	CompetenceType string
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`
	Grades         []int         `bun:",array"`
	Color          sql.NullString
	CreatedAt      time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt      sql.NullTime `bun:",soft_delete,nullzero"`
	CurriculumID   sql.NullString
}

type Report struct {
	bun.BaseModel

	ID           string `bun:",nullzero,pk"`
	FileBucketID sql.NullString
	FileName     sql.NullString
	Status       ReportStatus
	Type         ReportType
	AccountID    string
	Account      *Account `bun:"rel:belongs-to"`

	FilterTags []string `bun:",array"`

	StudentAccountID string
	StudentAccount   *Account `bun:"rel:belongs-to"`

	From time.Time
	To   time.Time

	Meta      sql.NullString
	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}

func (r *Report) GetMimeType() string {
	if r.Type == ReportTypeDocx || r.Type == ReportTypeDocxSubjects {
		return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
	}
	return "application/pdf"
}
func (r *Report) GetFileEnding() string {
	if r.Type == ReportTypeDocx || r.Type == ReportTypeDocxSubjects {
		return "docx"
	}
	return "pdf"
}

type ReportStatus string
type ReportType string

var (
	ReportStatusPending ReportStatus = "pending"
	ReportStatusDone    ReportStatus = "done"
	ReportStatusError   ReportStatus = "error"

	ReportTypeReport       ReportType = "report"
	ReportTypeSubjects     ReportType = "subjects"
	ReportTypeDocx         ReportType = "report_docx"
	ReportTypeDocxSubjects ReportType = "subjects_docx"
)

type Entry struct {
	bun.BaseModel

	ID        string `bun:",nullzero,pk"`
	Date      time.Time
	Body      string
	AccountID string
	Account   *Account     `bun:"-,rel:belongs-to"`
	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`

	EntryAccounts           []EntryAccount           `bun:",rel:has-many"`
	EntryAccountCompetences []EntryAccountCompetence `bun:",rel:has-many"`
}

type EntryAccountCompetence struct {
	bun.BaseModel

	ID           string `bun:",nullzero,pk"`
	Level        int
	AccountID    string
	Account      *Account `bun:"-,rel:belongs-to"`
	EntryID      string
	Entry        *Entry `bun:"-,rel:belongs-to"`
	CompetenceID string
	Competence   *Competence  `bun:"-,rel:belongs-to"`
	CreatedAt    time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt    sql.NullTime `bun:",soft_delete,nullzero"`
}

type EntryAccount struct {
	bun.BaseModel

	ID        string `bun:",nullzero,pk"`
	EntryID   string
	Entry     *Entry `bun:"-,rel:belongs-to"`
	AccountID string
	Account   *Account     `bun:"-,rel:belongs-to"`
	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}

type User struct {
	ID    uuid.UUID
	Email string
}

type Tag struct {
	bun.BaseModel

	ID             string `bun:",nullzero,pk"`
	Name           string
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`

	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
	CreatedBy string
}

type EntryTag struct {
	bun.BaseModel

	ID             string `bun:",nullzero,pk"`
	EntryID        string
	Entry          *Entry `bun:"-,rel:belongs-to"`
	TagID          string
	Tag            *Tag `bun:"-,rel:belongs-to"`
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`

	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}

type Event struct {
	bun.BaseModel

	ID             string `bun:",nullzero,pk"`
	Title          string
	Body           string
	StartsAt       time.Time
	EndsAt         time.Time
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`

	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}

type EntryEvent struct {
	bun.BaseModel

	ID      string `bun:",nullzero,pk"`
	EntryID string
	Entry   *Entry `bun:"-,rel:belongs-to"`
	EventID string
	Event   *Event `bun:"-,rel:belongs-to"`

	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}

type EventCompetences struct {
	bun.BaseModel

	ID      string `bun:",nullzero,pk"`
	EventID string
	Event   *Event `bun:"-,rel:belongs-to"`

	CompetenceID string
	Competence   *Competence `bun:"-,rel:belongs-to"`

	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}
