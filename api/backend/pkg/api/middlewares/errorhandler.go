package middlewares

import (
	"database/sql"
	"errors"
	"github.com/dokedu/dokedu-api-beta/services/pkg/api/status"
	"github.com/dokedu/dokedu-api-beta/services/pkg/helper"
	"github.com/labstack/echo/v4"
	"github.com/uptrace/bun/driver/pgdriver"
	"golang.org/x/crypto/bcrypt"
	"net/http"
)

func ErrorHandler() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			ctx := c.(helper.ApiContext)

			err := next(ctx)
			if err != nil {
				var httpErr *echo.HTTPError
				if errors.As(err, &httpErr) {
					return httpErr
				}

				if errors.Is(err, sql.ErrNoRows) {
					return echo.NewHTTPError(http.StatusNotFound, status.ErrNotFound)
				}

				if errors.Is(err, bcrypt.ErrMismatchedHashAndPassword) {
					return echo.NewHTTPError(http.StatusNotFound, status.ErrNotFound)
				}

				var e pgdriver.Error
				if errors.As(err, &e) {
					if e.IntegrityViolation() {
						return echo.NewHTTPError(http.StatusBadRequest, status.ErrIntegrity)
					}
				}

				c.Logger().Error(err)
				return echo.NewHTTPError(http.StatusInternalServerError, status.ErrInternal)
			}

			return nil
		}
	}
}
