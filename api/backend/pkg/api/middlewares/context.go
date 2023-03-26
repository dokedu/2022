package middlewares

import (
	"github.com/dokedu/dokedu-api-beta/services/pkg/helper"
	"github.com/labstack/echo/v4"
)

func Context(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		ctx := helper.ApiContext{Context: c}
		return next(ctx)
	}
}
