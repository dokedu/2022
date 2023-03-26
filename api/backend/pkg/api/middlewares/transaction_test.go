package middlewares_test

import (
	"context"
	"errors"
	"github.com/dokedu/dokedu-api-beta/services/pkg/api/middlewares"
	"github.com/dokedu/dokedu-api-beta/services/pkg/config"
	"github.com/dokedu/dokedu-api-beta/services/pkg/db"
	"github.com/dokedu/dokedu-api-beta/services/pkg/helper"
	"github.com/labstack/echo/v4"
	"github.com/matoous/go-nanoid/v2"
	"github.com/stretchr/testify/assert"
	"github.com/uptrace/bun"
	"github.com/uptrace/bun/driver/pgdriver"
	"net/http"
	"net/http/httptest"
	"testing"
)

const schema = `
CREATE TABLE "test_models" (
	"id" TEXT PRIMARY KEY,
	"should_exist" BOOLEAN
);`

type testModel struct {
	bun.BaseModel
	ID          string `bun:",pk"`
	ShouldExist bool   // indicated whether it could have been committed or not
}

func testDatabase() (*db.DB, error) {
	cfg, err := config.Load()
	if err != nil {
		return nil, err
	}

	db, err := db.New(cfg.DBConfig)
	if err != nil {
		return nil, err
	}

	_, err = db.Exec(schema)
	var pgError pgdriver.Error
	if err != nil {
		if errors.As(err, &pgError) {
			code := pgError.Field(byte('C'))
			if code != "42P07" { // code != table already exists
				return nil, pgError
			}

			_, err = db.NewTruncateTable().Model(&testModel{}).Exec(context.Background())
			if err != nil {
				return nil, err
			}
		} else {
			return db, err
		}
	}

	return db, nil
}

func testApi(db *db.DB) (*echo.Echo, error) {
	e := echo.New()
	e.Use(middlewares.Context)

	m := middlewares.Transaction(db)
	e.Use(m)

	successHandler := echo.HandlerFunc(func(c echo.Context) error {
		ctx := c.(helper.ApiContext)

		uid := gonanoid.Must()
		m := testModel{
			ID:          uid,
			ShouldExist: true,
		}

		_, err := ctx.Tx.NewInsert().Model(&m).Exec(c.Request().Context())
		if err != nil {
			return err
		}

		return nil
	})

	nonSuccessHandler := echo.HandlerFunc(func(c echo.Context) error {
		ctx := c.(helper.ApiContext)

		uid := gonanoid.Must()

		m := testModel{
			ID:          uid,
			ShouldExist: false,
		}

		_, err := ctx.Tx.NewInsert().Model(&m).Exec(c.Request().Context())
		if err != nil {
			return err
		}

		return echo.NewHTTPError(401, "non-success")
	})

	errorHandler := echo.HandlerFunc(func(c echo.Context) error {
		ctx := c.(helper.ApiContext)

		uid := gonanoid.Must()

		m := testModel{
			ID:          uid,
			ShouldExist: false,
		}

		_, err := ctx.Tx.NewInsert().Model(&m).Exec(c.Request().Context())
		if err != nil {
			return err
		}

		return errors.New("oops")
	})

	e.GET("/success", successHandler)
	e.GET("/non-success", nonSuccessHandler)
	e.GET("/error", errorHandler)

	return e, nil
}

func TestTransactionSuccess(t *testing.T) {
	db, err := testDatabase()
	assert.NoError(t, err)

	api, err := testApi(db)
	assert.NoError(t, err)

	req := httptest.NewRequest(http.MethodGet, "/success", nil)
	rec := httptest.NewRecorder()
	api.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusOK, rec.Code)

	req.Context()

	var m testModel
	ctx := context.Background()
	count, err := db.NewSelect().Model(&m).Where("should_exist = ?", true).Count(ctx)
	assert.NoError(t, err)

	assert.Equal(t, 1, count)
}

func TestTransactionNonSuccess(t *testing.T) {
	db, err := testDatabase()
	assert.NoError(t, err)

	api, err := testApi(db)
	assert.NoError(t, err)

	req := httptest.NewRequest(http.MethodGet, "/non-success", nil)
	rec := httptest.NewRecorder()
	api.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusUnauthorized, rec.Code)

	var m testModel
	ctx := context.Background()
	count, err := db.NewSelect().Model(&m).Where("should_exist = ?", false).Count(ctx)
	assert.NoError(t, err)

	assert.Equal(t, 0, count)
}

func TestTransactionError(t *testing.T) {
	db, err := testDatabase()
	assert.NoError(t, err)

	api, err := testApi(db)
	assert.NoError(t, err)

	req := httptest.NewRequest(http.MethodGet, "/error", nil)
	rec := httptest.NewRecorder()
	api.ServeHTTP(rec, req)
	assert.Equal(t, 500, rec.Code)

	var m testModel
	ctx := context.Background()
	count, err := db.NewSelect().Model(&m).Where("should_exist = ?", false).Count(ctx)
	assert.NoError(t, err)

	assert.Equal(t, 0, count)
}
