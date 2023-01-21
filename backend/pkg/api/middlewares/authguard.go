package middlewares

import (
	"github.com/dokedu/dokedu-api-beta/services/pkg/api/status"
	"github.com/dokedu/dokedu-api-beta/services/pkg/helper"
	"net/http"

	"github.com/labstack/echo/v4"
)

// AuthGuard can hold optional config
func AuthGuard() func(next echo.HandlerFunc) echo.HandlerFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			ctx := c.(helper.ApiContext)
			if ctx.Claims.Sub == "" {
				return echo.NewHTTPError(http.StatusUnauthorized, status.ErrUnauthorized)
			}

			return next(ctx)
		}
	}
}
