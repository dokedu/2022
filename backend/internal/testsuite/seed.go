package testsuite

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/dokedu/dokedu-api-beta/services/pkg/db"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"github.com/google/uuid"
	gonanoid "github.com/matoous/go-nanoid/v2"
	"time"
)

type Seed struct {
	suite *TestSuite
	db    *db.DB
}

func NewSeed(suite *TestSuite, db *db.DB) *Seed {
	return &Seed{
		suite: suite,
		db:    db,
	}
}

func (s *Seed) UserWithOrg() (string, models.Organisation, models.Account) {
	uID := uuid.Must(uuid.NewUUID())
	email := fmt.Sprintf("%s@dokedu.email", uID.String())

	_, err := s.db.NewInsert().Model(&map[string]interface{}{
		"id":                 uID,
		"instance_id":        "00000000-0000-0000-0000-000000000000",
		"role":               "authenticated",
		"email":              email,
		"encrypted_password": "$2a$10$vf9nf1zrRZlNd0mAEv.VGeCA/TYMZSOEfdcWACV..6mnWrxNZNy7O",
		"raw_app_meta_data":  "{\"provider\": \"email\", \"providers\": [\"email\"]}",
	}).Table("auth.users").Exec(s.suite.ctx)
	s.suite.NoError(err)

	res := s.suite.Request("POST", "/auth/init_account", nil, uID.String())
	s.suite.Equal(200, res.Code)

	// get the identity
	var identity models.Identity
	err = s.db.NewSelect().Model(&identity).Where("user_id = ?", uID).Scan(s.suite.ctx)
	s.suite.NoError(err)

	// get the account
	var account models.Account
	err = s.db.NewSelect().Model(&account).Where("identity_id = ?", identity.ID).Scan(s.suite.ctx)
	s.suite.NoError(err)

	// get the organisation
	var organisation models.Organisation
	err = s.db.NewSelect().Model(&organisation).Where("id = ?", account.OrganisationID).Scan(s.suite.ctx)
	s.suite.NoError(err)

	return uID.String(), organisation, account
}

func (s *Seed) Competences(orgID string) []models.Competence {
	competences := make([]models.Competence, 50)
	var parentID sql.NullString
	typ := "subject"
	for i := 0; i < 50; i++ {
		if i > 5 {
			parentID = sql.NullString{Valid: true, String: competences[i%5].ID}
			typ = "group"
		}
		if i > 20 {
			parentID = sql.NullString{Valid: true, String: competences[6+i%20].ID}
			typ = "competence"
		}
		competences[i] = models.Competence{
			ID:             gonanoid.Must(),
			OrganisationID: orgID,
			Name:           fmt.Sprintf("%s %d", typ, i),
			CompetenceID:   parentID,
			Grades:         []int{1},
			CompetenceType: typ,
		}
	}

	_, err := s.db.NewInsert().Model(&competences).Exec(s.suite.ctx)
	s.suite.NoError(err)

	return competences
}

func (s *Seed) Tags(userID string, orgID string, createdByID string) ([]models.Tag, []string) {
	tx, err := s.db.NewTx(context.Background(), nil)
	defer func() {
		if err != nil {
			_ = tx.Rollback()
		}
	}()

	s.suite.NoError(err)
	err = tx.SetUser(uuid.MustParse(userID))
	s.suite.NoError(err)

	tags := []models.Tag{
		{
			ID:             gonanoid.Must(),
			Name:           "TestTag1",
			CreatedBy:      createdByID,
			OrganisationID: orgID,
		},
		{
			ID:             gonanoid.Must(),
			Name:           "TestTag2",
			CreatedBy:      createdByID,
			OrganisationID: orgID,
		},
		{
			ID:             gonanoid.Must(),
			Name:           "TestTag3",
			CreatedBy:      createdByID,
			OrganisationID: orgID,
		},
	}

	_, err = tx.NewInsert().Model(&tags).Exec(s.suite.ctx)
	s.suite.NoError(err)

	err = tx.Commit()
	s.suite.NoError(err)

	tagIDs := make([]string, len(tags))
	for i, tag := range tags {
		tagIDs[i] = tag.ID
	}

	return tags, tagIDs
}

func (s *Seed) CreateEntryAccount(orgID string, accountID string, competences []models.Competence, tags []string) (models.Entry, models.EntryAccount) {
	entry := models.Entry{
		Date:      time.Now(),
		Body:      "{\"type\": \"doc\",\"content\": [{\"type\": \"paragraph\",\"content\": [{\"text\": \"this is a test!\",\"type\": \"text\"}]}]}",
		AccountID: accountID,
	}

	_, err := s.db.NewInsert().Model(&entry).Exec(s.suite.ctx)
	s.suite.NoError(err)

	// create entry_account
	entryAccount := models.EntryAccount{
		EntryID:   entry.ID,
		AccountID: accountID,
	}

	_, err = s.db.NewInsert().Model(&entryAccount).Exec(s.suite.ctx)
	s.suite.NoError(err)

	// create entry_account_competence
	for _, competence := range competences {
		eac := models.EntryAccountCompetence{
			Level:        2,
			AccountID:    accountID,
			EntryID:      entry.ID,
			CompetenceID: competence.ID,
		}

		_, err = s.db.NewInsert().Model(&eac).Exec(s.suite.ctx)
		s.suite.NoError(err)
	}

	// create entry_tags
	if len(tags) > 0 {
		entryTags := make([]models.EntryTag, len(tags))
		for i, tag := range tags {
			entryTags[i] = models.EntryTag{
				OrganisationID: orgID,
				TagID:          tag,
				EntryID:        entry.ID,
			}
		}
		_, err = s.db.NewInsert().Model(&entryTags).Exec(s.suite.ctx)
		s.suite.NoError(err)
	}

	return entry, entryAccount
}

func (s *Seed) CreateEntryAccountCompetence(accountID string, competenceID string, level int) (models.Entry, models.EntryAccount) {
	entry := models.Entry{
		Date:      time.Now(),
		Body:      "{\"type\": \"doc\",\"content\": [{\"type\": \"paragraph\",\"content\": [{\"text\": \"this is a test!\",\"type\": \"text\"}]}]}",
		AccountID: accountID,
	}

	_, err := s.db.NewInsert().Model(&entry).Exec(s.suite.ctx)
	s.suite.NoError(err)

	// create entry_account
	entryAccount := models.EntryAccount{
		EntryID:   entry.ID,
		AccountID: accountID,
	}

	_, err = s.db.NewInsert().Model(&entryAccount).Exec(s.suite.ctx)
	s.suite.NoError(err)

	// create entry_account_competence
	eac := models.EntryAccountCompetence{
		Level:        level,
		AccountID:    accountID,
		EntryID:      entry.ID,
		CompetenceID: competenceID,
	}

	_, err = s.db.NewInsert().Model(&eac).Exec(s.suite.ctx)
	s.suite.NoError(err)

	return entry, entryAccount
}

func (s *Seed) CreateEvent(orgID string, title string, competences []models.Competence) models.Event {
	event := models.Event{
		Title:          title,
		Body:           "test",
		StartsAt:       time.Now().AddDate(-1, 0, 0),
		EndsAt:         time.Now().AddDate(0, 5, 0),
		OrganisationID: orgID,
	}

	_, err := s.db.NewInsert().Model(&event).Returning("id").Exec(s.suite.ctx)
	s.suite.NoError(err)

	if len(competences) > 0 {
		eventCompetences := make([]models.EventCompetences, len(competences))
		for i, competence := range competences {
			eventCompetences[i] = models.EventCompetences{
				EventID:      event.ID,
				CompetenceID: competence.ID,
			}
		}

		_, err := s.db.NewInsert().Model(&eventCompetences).Exec(s.suite.ctx)
		s.suite.NoError(err)
	}

	return event
}

func (s *Seed) CreateEntryEvent(entryID string, eventID string) {
	entryEvent := models.EntryEvent{
		EntryID: entryID,
		EventID: eventID,
	}

	_, err := s.db.NewInsert().Model(&entryEvent).Exec(s.suite.ctx)
	s.suite.NoError(err)
}

func (s *Seed) CreateEntryTag(orgID string, entryID string, tagID string) {
	entryEvent := models.EntryTag{
		EntryID:        entryID,
		TagID:          tagID,
		OrganisationID: orgID,
	}

	_, err := s.db.NewInsert().Model(&entryEvent).Exec(s.suite.ctx)
	s.suite.NoError(err)
}
