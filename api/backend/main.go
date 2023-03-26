package main

import (
	"context"
	"github.com/dokedu/dokedu-api-beta/services/pkg/api"
	"github.com/dokedu/dokedu-api-beta/services/pkg/config"
	"github.com/dokedu/dokedu-api-beta/services/pkg/db"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"github.com/dokedu/dokedu-api-beta/services/pkg/modules"
	log "github.com/sirupsen/logrus"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("failed to load configuration: %+v", err)
	}

	dbI, err := db.New(cfg.DBConfig)
	if err != nil {
		log.Fatalf("could not initialise database connection: %+v", err)
	}

	mods, err := modules.New(cfg.MeiliConfig, cfg.SupabaseConfig, cfg.PrinterConfig, dbI.DB)
	if err != nil {
		log.Fatalf("could not initialise modules: %+v", err)
	}

	apiI := api.New(cfg.ApiConfig, dbI, mods)

	go func() {
		log.Infof("Resetting meilisearch index")

		var orgs []models.Organisation
		err = dbI.NewSelect().Model(&orgs).Scan(context.Background())

		if err != nil {
			log.Errorf("Could not reset meilisearch index: %+v", err)
		}

		for _, org := range orgs {
			if err != nil {
				log.Errorf("err acquiring semaphore: %+v", err)
			}

			err = mods.MeiliSearch.ResetIndexForOrganisation(org.ID)
			if err != nil {
				log.Errorf("Could not index organisation: %+v", err)
			}
		}
	}()

	if err := apiI.Start(); err != nil {
		log.Fatalf("error during api start: %+v\n", err)
	}
}
