package helper

import (
	"example/pkg/db"
	"example/pkg/jwt"
	"github.com/labstack/echo/v4"
)

type APIContext struct {
	echo.Context
	Tx     *db.DBTX
	Claims jwt.Claims
}
