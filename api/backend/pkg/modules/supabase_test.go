package modules_test

import (
	"fmt"
	gonanoid "github.com/matoous/go-nanoid/v2"
)

func (ms *ModuleSuite) Test_InviteUserByEmail() {
	user, err := ms.Modules.Supabase.InviteUserByEmail(fmt.Sprintf("%s@dokedu.email", gonanoid.Must()))
	ms.NoError(err)
	ms.NotEmpty(user.ID)
}
