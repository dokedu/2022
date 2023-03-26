package helper

import (
	"github.com/dokedu/dokedu-api-beta/services/pkg/db"
	"github.com/dokedu/dokedu-api-beta/services/pkg/jwt"
	"github.com/labstack/echo/v4"
)

type ApiContext struct {
	echo.Context
	Tx     *db.Tx
	Claims jwt.Claims
}

//func (c *ApiContext) GetCurrentUser() (*models.User, error) {
//	user := &models.User{}
//	err := c.Tx.NewSelect().Model(user).Where("id = ?", c.UserID).Scan(c.Request().Context())
//	if err != nil {
//		return nil, err
//	}
//
//	return user, nil
//}
