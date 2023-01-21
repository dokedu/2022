package middlewares_test

import (
	"bytes"
	"encoding/json"
	"github.com/dokedu/dokedu-api-beta/services/internal/testsuite"
	"github.com/dokedu/dokedu-api-beta/services/pkg/api/middlewares"
	"github.com/dokedu/dokedu-api-beta/services/pkg/api/status"
	"github.com/dokedu/dokedu-api-beta/services/pkg/helper"
	"github.com/dokedu/dokedu-api-beta/services/pkg/jwt"
	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/suite"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
)

type MiddlewareSuite struct {
	testsuite.TestSuite
}

func apiResOK(c echo.Context) error {
	return c.JSON(200, status.ResOK)
}

func apiResClaims(c echo.Context) error {
	ctx := c.(helper.ApiContext)
	return c.JSON(http.StatusOK, ctx.Claims)
}

func Test_MiddlewareSuite(t *testing.T) {
	ts, err := testsuite.New()
	if err != nil {
		t.Errorf("failed to intialise new testsuite: %+v", err)
	}

	cfg := *ts.Config
	cfg.ApiConfig.ValidateRequests = false

	ms := &MiddlewareSuite{
		TestSuite: *ts,
	}

	ms.Api.Echo.Use()
	ms.Api.GET("/test/claims", apiResClaims)
	ms.Api.GET("/test/authGuardLoggedIn", apiResOK, middlewares.AuthGuard())

	suite.Run(t, ms)
}

func (ms *MiddlewareSuite) Request(method string, path string, payload interface{}, user string) *httptest.ResponseRecorder {
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		ms.Errorf(err, "failed to marshal payload")
	}

	req := httptest.NewRequest(method, "http://localhost:3000"+path, bytes.NewReader(payloadBytes))
	if user != "" {
		claims := jwt.Claims{
			Sub: user,
		}

		sToken, err := ms.Api.JwtSigner.Sign(claims)
		if err != nil {
			ms.Errorf(err, "failed to sign token")
		}

		req.Header.Set("Authorization", sToken)
	}

	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()

	ms.Api.ServeHTTP(rec, req)
	return rec
}

func (ms *MiddlewareSuite) BindResponse(rec *httptest.ResponseRecorder, destination interface{}) {
	data, err := io.ReadAll(rec.Body)
	if err != nil {
		ms.Errorf(err, "failed to read bytes")
	}

	err = json.Unmarshal(data, destination)
	if err != nil {
		ms.Errorf(err, "failed to unmarshal from JSON")
	}
}
