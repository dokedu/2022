package middlewares_test

import (
	"github.com/dokedu/dokedu-api-beta/services/pkg/jwt"
	"net/http/httptest"
)

// the auth middleware should add claims to the context
func (ms *MiddlewareSuite) Test_Auth() {
	res := ms.Request("GET", "/test/claims", nil, "U1")
	ms.Equal(200, res.Code)

	var claims jwt.Claims
	ms.BindResponse(res, &claims)

	ms.Equal("U1", claims.Sub)
}

// does not add claims when no auth header is supplied
func (ms *MiddlewareSuite) Test_Auth_NoHeader() {
	res := ms.Request("GET", "/test/claims", nil, "")
	ms.Equal(200, res.Code)

	var claims jwt.Claims
	ms.BindResponse(res, &claims)

	ms.Equal("", claims.Sub)
}

// returns 401 on invalid auth header
func (ms *MiddlewareSuite) Test_Auth_Invalid() {
	req := httptest.NewRequest("GET", "http://localhost:3000"+"/test/claims", nil)
	req.Header.Add("Authorization", "INVALID!!")
	res := httptest.NewRecorder()
	ms.Api.ServeHTTP(res, req)

	ms.Equal(401, res.Code)
}
