package jwt

import (
	"example/graph/model"
	"github.com/golang-jwt/jwt"
)

type Claims struct {
	jwt.StandardClaims
	User model.User `json:"user"`
}

func NewClaims(user model.User) Claims {
	return Claims{
		User: user,
	}
}

func (c Claims) Valid() error {
	// TODO: validate claims

	return nil
}
