package middlewares

import (
	"github.com/dokedu/dokedu-api-beta/services/pkg/api/status"
	"github.com/dokedu/dokedu-api-beta/services/pkg/helper"
	"github.com/dokedu/dokedu-api-beta/services/pkg/jwt"
	"net/http"
	"strings"

	"github.com/labstack/echo/v4"
)

func Auth(jwtSigner jwt.Signer) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			ctx := c.(helper.ApiContext)

			authHeader := c.Request().Header.Get("Authorization")
			authHeader = strings.TrimPrefix(authHeader, "Bearer ")
			if authHeader != "" {
				claims, err := jwtSigner.ParseAndValidate(authHeader)
				if err != nil {
					return echo.NewHTTPError(http.StatusUnauthorized, status.ErrUnauthorized)
				}

				ctx.Claims = claims
			}

			return next(ctx)
		}
	}
}
