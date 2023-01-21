package middlewares

import (
	"github.com/dokedu/dokedu-api-beta/services/pkg/db"
	"github.com/dokedu/dokedu-api-beta/services/pkg/helper"
	"github.com/labstack/echo/v4"
)

func Transaction(db *db.DB) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return echo.HandlerFunc(func(c echo.Context) error {
			ctx := c.(helper.ApiContext)
			if ctx.Tx == nil {
				tx, err := db.NewTx(ctx.Request().Context(), nil)
				if err != nil {
					return err
				}

				ctx.Tx = &tx
			}

			if apiErr := next(ctx); apiErr != nil {
				if err := ctx.Tx.Rollback(); err != nil {
					ctx.Logger().Errorf("failed to rollback transaction: %w", err)
					return apiErr
				}
				ctx.Logger().Debugf("transaction rollback: %w", apiErr)
				return apiErr
			}

			ctx.Logger().Debugf("transaction committed")
			if err := ctx.Tx.Commit(); err != nil {
				ctx.Logger().Errorf("failed to commit transaction rollback: %w", err)
				return err
			}

			return nil
		})
	}
}
