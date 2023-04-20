package model

import (
	"database/sql"
	"github.com/uptrace/bun"
	"time"
)

type Organisation struct {
	bun.BaseModel

	ID        string `bun:",nullzero,pk"`
	Name      string
	OwnerID   string
	Owner     *User        `bun:"-,rel:belongs-to"`
	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}

type UserRole string

const (
	UserRoleOwner    UserRole = "OWNER"
	UserRoleAdmin    UserRole = "ADMIN"
	UserRoleTeacher  UserRole = "TEACHER"
	UserRoleEducator UserRole = "EDUCATOR"
	UserRoleStudent  UserRole = "STUDENT"
)

var AllUserRole = []UserRole{
	UserRoleOwner,
	UserRoleAdmin,
	UserRoleTeacher,
	UserRoleEducator,
	UserRoleStudent,
}

type User struct {
	bun.BaseModel

	ID             string        `bun:",nullzero,pk" json:"id"`
	Role           UserRole      `json:"role"`
	Email          string        `json:"email"`
	FirstName      string        `json:"firstName"`
	LastName       string        `json:"lastName"`
	OrganisationID string        `json:"organisationId"`
	Organisation   *Organisation `bun:"-,rel:belongs-to" json:"organisation"`
	CreatedAt      time.Time     `bun:",nullzero,notnull,default:current_timestamp" json:"createdAt"`
	DeletedAt      sql.NullTime  `bun:",soft_delete,nullzero" json:"deletedAt"`
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
	UserID       string
	User         *User `bun:"rel:belongs-to"`

	FilterTags []string `bun:",array"`

	StudentUserID string
	StudentUser   *User `bun:"rel:belongs-to"`

	From time.Time
	To   time.Time

	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`

	Meta      sql.NullString
	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}

type ReportStatus string
type ReportType string

var (
	ReportStatusPending    ReportStatus = "pending"
	ReportStatusDone       ReportStatus = "done"
	ReportStatusError      ReportStatus = "error"
	ReportTypeReport       ReportType   = "report"
	ReportTypeSubjects     ReportType   = "subjects"
	ReportTypeDocx         ReportType   = "report_docx"
	ReportTypeDocxSubjects ReportType   = "subjects_docx"
)

type Entry struct {
	bun.BaseModel

	ID             string `bun:",nullzero,pk"`
	Date           time.Time
	Body           string `bun:"type:jsonb"`
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`
	UserID         string
	User           *User        `bun:"-,rel:belongs-to"`
	CreatedAt      time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt      sql.NullTime `bun:",soft_delete,nullzero"`

	EntryUsers           []EntryUser           `bun:",rel:has-many"`
	EntryUserCompetences []EntryUserCompetence `bun:",rel:has-many"`
	EntryEvents          []EntryEvent          `bun:",rel:has-many"`
	EntryFiles           []EntryFile           `bun:",rel:has-many"`
	EntryTags            []EntryTag            `bun:",rel:has-many"`
}

type EntryUserCompetence struct {
	bun.BaseModel

	ID             string `bun:",nullzero,pk"`
	Level          int
	UserID         string
	User           *User `bun:"-,rel:belongs-to"`
	EntryID        string
	Entry          *Entry `bun:"-,rel:belongs-to"`
	CompetenceID   string
	Competence     *Competence `bun:"-,rel:belongs-to"`
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`
	CreatedAt      time.Time     `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt      sql.NullTime  `bun:",soft_delete,nullzero"`
}

type EntryUser struct {
	bun.BaseModel

	ID             string `bun:",nullzero,pk"`
	EntryID        string
	Entry          *Entry `bun:"-,rel:belongs-to"`
	UserID         string
	User           *User `bun:"-,rel:belongs-to"`
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`
	CreatedAt      time.Time     `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt      sql.NullTime  `bun:",soft_delete,nullzero"`
}

type Tag struct {
	bun.BaseModel

	ID             string `bun:",nullzero,pk"`
	Name           string
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`

	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
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

	ID             string `bun:",nullzero,pk"`
	EntryID        string
	Entry          *Entry `bun:"-,rel:belongs-to"`
	EventID        string
	Event          *Event `bun:"-,rel:belongs-to"`
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`

	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}

type EntryFile struct {
	bun.BaseModel

	ID             string `bun:",nullzero,pk"`
	EntryID        string
	Entry          *Entry `bun:"-,rel:belongs-to"`
	FileBucketId   string
	FileName       string
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`

	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}

type EventCompetence struct {
	bun.BaseModel

	ID      string `bun:",nullzero,pk"`
	EventID string
	Event   *Event `bun:"-,rel:belongs-to"`

	CompetenceID   string
	Competence     *Competence `bun:"-,rel:belongs-to"`
	OrganisationID string
	Organisation   *Organisation `bun:"-,rel:belongs-to"`

	CreatedAt time.Time    `bun:",nullzero,notnull,default:current_timestamp"`
	DeletedAt sql.NullTime `bun:",soft_delete,nullzero"`
}
