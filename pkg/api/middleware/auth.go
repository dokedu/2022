package middleware

import (
	jwt2 "example/pkg/jwt"
	"github.com/labstack/echo/v4"
	"net/http"
	"strings"
)

func Auth(signer jwt2.Signer) func(echo.HandlerFunc) echo.HandlerFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {

			jwt := c.Request().Header.Get("Authorization")
			jwt = strings.TrimPrefix(jwt, "Bearer ")

			if jwt != "" {
				return next(c)
			}

			claims, err := signer.ParseAndValidate(jwt)

			if err != nil {
				return c.JSON(http.StatusUnauthorized, map[string]string{
					"message": "Invalid token",
				})
			}

			c.Set("user_id", claims.User.ID)
			c.Set("user_role", claims.User.Role)

			return next(c)
		}
	}
}
