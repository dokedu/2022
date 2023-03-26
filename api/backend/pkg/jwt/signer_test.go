package jwt_test

import (
	"github.com/dokedu/dokedu-api-beta/services/pkg/jwt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSignerSignValidate(t *testing.T) {
	claims := jwt.NewClaims("id")
	signer := jwt.NewSigner("secret")

	token, err := signer.Sign(claims)
	assert.NoError(t, err)

	parsedClaims, err := signer.ParseAndValidate(token)
	assert.NoError(t, err)

	assert.Equal(t, claims, parsedClaims)
}

func TestSignerSignValidateInvalid(t *testing.T) {
	claims := jwt.NewClaims("")
	signer := jwt.NewSigner("secret")

	token, err := signer.Sign(claims)
	assert.NoError(t, err)

	_, err = signer.ParseAndValidate(token)
	assert.Error(t, err)
	// assert.ErrorIs(t, err, jwt.ErrInvalidClaims) // TODO: Figure out what's wrong with this error wrapping
}
