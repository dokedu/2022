package api_test

import (
	"fmt"
	"github.com/dokedu/dokedu-api-beta/services/pkg/api"
	gonanoid "github.com/matoous/go-nanoid/v2"
)

func (as *ApiSuite) Test_InviteByEmail() {
	u, org, _ := as.Seed().UserWithOrg()

	email := fmt.Sprintf("%s@dokedu.email", gonanoid.Must())
	res := as.Request("POST", "/auth/invite", api.InviteUserRequest{
		Email:          email,
		FirstName:      "Test",
		LastName:       "Tester",
		OrganisationID: org.ID,
		Role:           "teacher",
	}, u)

	as.Equal(200, res.Code)

	// there should now be a teacher in the organisation
	cnt, err := as.DB.NewSelect().Table("accounts").Where("role = 'teacher'").Where("organisation_id = ?", org.ID).Count(as.Context())
	as.NoError(err)
	as.Equal(1, cnt)
}
