package testsuite

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"github.com/dokedu/dokedu-api-beta/services/pkg/api"
	"github.com/dokedu/dokedu-api-beta/services/pkg/config"
	"github.com/dokedu/dokedu-api-beta/services/pkg/db"
	"github.com/dokedu/dokedu-api-beta/services/pkg/jwt"
	"github.com/dokedu/dokedu-api-beta/services/pkg/modules"
	"github.com/labstack/echo/v4"
	"io"
	"net/http/httptest"

	"github.com/stretchr/testify/suite"
)

type TestSuite struct {
	suite.Suite
	ctx     context.Context
	DB      *db.DB
	Config  *config.Config
	seed    *Seed
	Api     *api.Api
	Modules *modules.Modules
}

func New() (*TestSuite, error) {
	cfg, err := config.Load()
	if err != nil {
		return nil, fmt.Errorf("could not load configuration: %w", err)
	}

	iDB, err := db.New(cfg.DBConfig)
	if err != nil {
		return nil, fmt.Errorf("error initialising database: %w", err)
	}

	mods, err := modules.New(cfg.MeiliConfig, cfg.SupabaseConfig, cfg.PrinterConfig, iDB.DB)
	apiI := api.New(cfg.ApiConfig, iDB, mods)

	if err != nil {
		return nil, fmt.Errorf("error initialising modules: %w", err)
	}

	s := *new(suite.Suite)
	return &TestSuite{
		Suite:   s,
		ctx:     context.Background(),
		DB:      iDB,
		Config:  cfg,
		Api:     apiI,
		Modules: mods,
	}, nil

}

func (ts *TestSuite) Context() context.Context {
	if ts.ctx == nil {
		ts.ctx = context.Background()
	}

	return ts.ctx
}

func (ts *TestSuite) Seed() *Seed {
	if ts.seed == nil {
		ts.seed = NewSeed(ts, ts.DB)
	}

	return ts.seed
}

func (ts *TestSuite) Int64Must(i int64, err error) int64 {
	ts.NoError(err)
	return i
}

func (ts *TestSuite) Request(method string, path string, payload interface{}, sub string) *httptest.ResponseRecorder {
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		ts.Errorf(err, "failed to marshal payload")
	}

	req := httptest.NewRequest(method, "http://localhost:3000"+path, bytes.NewReader(payloadBytes))
	if sub != "" {
		claims := jwt.Claims{
			Sub: sub,
		}

		sToken, err := ts.Api.JwtSigner.Sign(claims)
		if err != nil {
			ts.Errorf(err, "failed to sign token")
		}

		req.Header.Set("Authorization", sToken)
	}

	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()

	ts.Api.ServeHTTP(rec, req)
	return rec
}

func (ts *TestSuite) BindResponse(rec *httptest.ResponseRecorder, destination interface{}) {
	data, err := io.ReadAll(rec.Body)
	if err != nil {
		ts.Errorf(err, "failed to read bytes")
	}

	err = json.Unmarshal(data, destination)
	if err != nil {
		ts.Errorf(err, "failed to unmarshal from JSON")
	}
}
