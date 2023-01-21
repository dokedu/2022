package testsuite_test

import (
	"github.com/dokedu/dokedu-api-beta/services/internal/testsuite"
	"github.com/stretchr/testify/suite"
	"testing"
)

type SeedTestSuite struct {
	testsuite.TestSuite
}

func TestSeedTS(t *testing.T) {
	ts, err := testsuite.New()
	if err != nil {
		t.Errorf("failed to intialise new testsuite: %+v", err)
	}

	s := &SeedTestSuite{
		TestSuite: *ts,
	}
	suite.Run(t, s)
}

func (st *SeedTestSuite) Test_Seed() {
	id, account, org := st.Seed().UserWithOrg()
	st.NotEmpty(id)
	st.NotEmpty(account)
	st.NotEmpty(org)
}
