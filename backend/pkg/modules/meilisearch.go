package modules

import (
	"context"
	"errors"
	"fmt"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"github.com/meilisearch/meilisearch-go"
	log "github.com/sirupsen/logrus"
	"github.com/uptrace/bun"
	"io"
	"net/http"
	"time"
)

type MeiliSearchModule struct {
	Config           MeiliSearchConfig
	AdminMeiliClient *meilisearch.Client
	DB               *bun.DB
}

type MeiliSearchConfig struct {
	BaseURL   string
	PublicKey string
	AdminKey  string
}

func NewMeiliSearchModule(cfg MeiliSearchConfig, db *bun.DB) *MeiliSearchModule {
	// Create a new client
	client := meilisearch.NewClient(meilisearch.ClientConfig{
		Host:   cfg.BaseURL,
		APIKey: cfg.AdminKey,
	})

	return &MeiliSearchModule{
		Config:           cfg,
		AdminMeiliClient: client,
		DB:               db,
	}
}

func (ms *MeiliSearchModule) ResetIndexForOrganisation(organisationID string) error {
	ctx := context.Background()

	log.Infof("Resetting index for organisation %s", organisationID)

	index, err := ms.AdminMeiliClient.GetIndex(organisationID)
	if err == nil {
		// delete index
		ok, err := index.Delete(index.UID)
		if err != nil {
			return err
		}

		if !ok {
			return errors.New("could not delete index")
		}
	}

	// create index
	index, err = ms.AdminMeiliClient.CreateIndex(&meilisearch.IndexConfig{
		Uid:        organisationID,
		PrimaryKey: "id",
	})
	if err != nil {
		return err
	}

	// add default settings
	distinct := "id"
	_, err = index.UpdateSettings(&meilisearch.Settings{
		DistinctAttribute:    &distinct,
		StopWords:            []string{"der", "die", "das"},
		FilterableAttributes: []string{"competence_id", "competence_type", "type"},
	})
	if err != nil {
		return err
	}

	// query all competences
	var competences []*models.Competence
	err = ms.DB.NewSelect().Model(&competences).Where("organisation_id = ?", organisationID).Where("deleted_at is null").Scan(ctx)
	if err != nil {
		return err
	}

	// add parents to competences
	for _, competence := range competences {
		if competence.CompetenceID.Valid {
			// find parent
			for _, parentCandidate := range competences {
				if parentCandidate.ID == competence.CompetenceID.String {
					competence.Competence = parentCandidate
					break
				}
			}

			if competence.Competence == nil {
				return fmt.Errorf("competence %s parent not found", competence.ID)
			}
		}
	}

	// convert to meiliDocument
	documents := make([]MeiliDocument, len(competences))
	for i, competence := range competences {
		// parents?
		parents := make([]MeiliDocumentCompetenceParent, 0)
		currentID := competence.CompetenceID
		for currentID.Valid {
			var parent *models.Competence
			for _, candidate := range competences {
				if candidate.ID == currentID.String {
					parent = candidate
					break
				}
			}

			parents = append(parents, MeiliDocumentCompetenceParent{
				ID:             parent.ID,
				Name:           parent.Name,
				CompetenceType: parent.CompetenceType,
			})
			currentID = parent.CompetenceID
		}

		var deletedAt *time.Time
		var curriculumID, color, competenceID *string

		if competence.DeletedAt.Valid {
			deletedAt = &competence.DeletedAt.Time
		}

		if competence.CurriculumID.Valid {
			curriculumID = &competence.CurriculumID.String
		}

		if competence.Color.Valid {
			color = &competence.Color.String
		}

		if competence.CompetenceID.Valid {
			competenceID = &competence.CompetenceID.String
		}

		documents[i] = MeiliDocument{
			ID:   competence.ID,
			Type: MeiliDocumentTypeCompetence,
			MeiliDocumentCompetence: &MeiliDocumentCompetence{
				Name:           competence.Name,
				Parents:        parents,
				CompetenceID:   competenceID,
				CompetenceType: competence.CompetenceType,
				OrganisationID: competence.OrganisationID,
				Grades:         competence.Grades,
				Color:          color,
				CurriculumID:   curriculumID,
				CreatedAt:      competence.CreatedAt,
				DeletedAt:      deletedAt,
			},
		}
	}

	if len(documents) > 0 {
		_, err = index.AddDocuments(documents)
		if err != nil {
			return err
		}
	}

	return nil
}

func (ms *MeiliSearchModule) RedirectSearch(index string, body io.Reader) (*http.Response, error) {
	req, err := http.NewRequest("POST", fmt.Sprintf("%s/indexes/%s/search", ms.Config.BaseURL, index), body)
	if err != nil {
		return nil, err
	}

	if ms.Config.PublicKey != "" {
		req.Header.Set("X-Meili-API-Key", ms.Config.PublicKey)
	}

	req.Header.Set("Content-Type", "application/json")

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}

	return res, nil
}

type MeiliDocument struct {
	ID   string            `json:"id"`
	Type MeiliDocumentType `json:"type"`

	*MeiliDocumentCompetence
}

type MeiliDocumentCompetence struct {
	Name           string                          `json:"name"`
	Parents        []MeiliDocumentCompetenceParent `json:"parents"`
	CompetenceID   *string                         `json:"competence_id"`
	CompetenceType string                          `json:"competence_type"`
	OrganisationID string                          `json:"organisation_id"`
	Grades         []int                           `json:"grades"`
	Color          *string                         `json:"color"`
	CurriculumID   *string                         `json:"curriculum_id"`
	CreatedAt      time.Time                       `json:"created_at"`
	DeletedAt      *time.Time                      `json:"deleted_at"`
}

type MeiliDocumentCompetenceParent struct {
	ID             string `json:"id"`
	Name           string `json:"name"`
	CompetenceType string `json:"competence_type"`
}

type MeiliDocumentType string

const (
	MeiliDocumentTypeCompetence MeiliDocumentType = "competence"
)
