package main

import (
	"fmt"
	"github.com/dokedu/dokedu-api-beta/services/cmd/bun/migrations"
	"github.com/dokedu/dokedu-api-beta/services/pkg/config"
	"github.com/dokedu/dokedu-api-beta/services/pkg/db"
	"github.com/uptrace/bun"
	"github.com/uptrace/bun/migrate"
	"github.com/urfave/cli/v2"
	"log"
	"os"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal(err)
	}

	iDb, err := db.New(cfg.DBConfig)
	if err != nil {
		log.Fatal(err)
	}

	app := &cli.App{
		Name: "bun",
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:  "env",
				Value: "dev",
				Usage: "environment",
			},
		},
		Commands: []*cli.Command{
			newDBCommand(migrations.Migrations, iDb.DB),
		},
	}
	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}

func newDBCommand(migrations *migrate.Migrations, db *bun.DB) *cli.Command {
	return &cli.Command{
		Name:  "db",
		Usage: "manage database migrations",
		Subcommands: []*cli.Command{
			{
				Name:  "init",
				Usage: "create migration tables",
				Action: func(c *cli.Context) error {
					migrator := migrate.NewMigrator(db, migrations)
					return migrator.Init(c.Context)
				},
			},
			{
				Name:  "migrate",
				Usage: "migrate database",
				Action: func(c *cli.Context) error {
					migrator := migrate.NewMigrator(db, migrations)

					group, err := migrator.Migrate(c.Context)
					if err != nil {
						return err
					}

					if group.ID == 0 {
						fmt.Printf("there are no new migrations to run\n")
						return nil
					}

					fmt.Printf("migrated to %s\n", group)
					return nil
				},
			},
			{
				Name:  "rollback",
				Usage: "rollback the last migration group",
				Action: func(c *cli.Context) error {
					migrator := migrate.NewMigrator(db, migrations)

					group, err := migrator.Rollback(c.Context)
					if err != nil {
						return err
					}

					if group.ID == 0 {
						fmt.Printf("there are no groups to roll back\n")
						return nil
					}

					fmt.Printf("rolled back %s\n", group)
					return nil
				},
			},
			{
				Name:  "lock",
				Usage: "lock migrations",
				Action: func(c *cli.Context) error {
					migrator := migrate.NewMigrator(db, migrations)
					return migrator.Lock(c.Context)
				},
			},
			{
				Name:  "unlock",
				Usage: "unlock migrations",
				Action: func(c *cli.Context) error {
					migrator := migrate.NewMigrator(db, migrations)
					return migrator.Unlock(c.Context)
				},
			},
			{
				Name:  "create_sql",
				Usage: "create SQL migration",
				Action: func(c *cli.Context) error {
					migrator := migrate.NewMigrator(db, migrations)

					mf, err := migrator.CreateSQLMigrations(c.Context, c.Args().Get(0))
					if err != nil {
						return err
					}

					for _, file := range mf {
						fmt.Printf("created migration %s (%s)\n", file.Name, file.Path)
					}

					return nil
				},
			},
			{
				Name:  "status",
				Usage: "print migrations status",
				Action: func(c *cli.Context) error {
					migrator := migrate.NewMigrator(db, migrations)

					status, err := migrator.MigrationsWithStatus(c.Context)
					if err != nil {
						return err
					}

					fmt.Printf("migrations: %v\n", status.Applied())
					fmt.Printf("new migrations: %v\n", status.Unapplied())
					fmt.Printf("last group: %s\n", status.LastGroup().String())
					return nil
				},
			},
		},
	}
}
