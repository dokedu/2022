package middlewares_test

// the authGuard should let authenticated requests through
func (ms *MiddlewareSuite) Test_AuthGuard() {
	res := ms.Request("GET", "/test/authGuardLoggedIn", nil, "U1")
	ms.Equal(200, res.Code)
}

// returns 401 on unauthenticated requests
func (ms *MiddlewareSuite) Test_AuthGuard_Unauthenticated() {
	res := ms.Request("GET", "/test/authGuardLoggedIn", nil, "")
	ms.Equal(401, res.Code)
}
