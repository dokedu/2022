package jwt_test

import (
	"github.com/dokedu/dokedu-api-beta/services/pkg/jwt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestClaimsValid(t *testing.T) {
	claims := jwt.NewClaims("someID")

	// should be valid
	err := claims.Valid()
	assert.NoError(t, err)
}

func TestClaimsInvalid(t *testing.T) {
	// all should be invalid
	claims := jwt.NewClaims("")
	err := claims.Valid()
	assert.Error(t, err, jwt.ErrInvalidClaims)
}
