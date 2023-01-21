package jwt

import (
	"fmt"
	"github.com/golang-jwt/jwt"
)

type Claims struct {
	jwt.StandardClaims
	Sub string `json:"sub"`
}

func NewClaims(sub string) Claims {
	return Claims{
		Sub: sub,
	}
}

func (c Claims) Valid() error {
	if c.Sub == "" {
		return fmt.Errorf("%w: missing sub", ErrInvalidClaims)
	}

	return nil
}
