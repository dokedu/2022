package modules_test

import (
	"github.com/dokedu/dokedu-api-beta/services/internal/testsuite"
	"github.com/stretchr/testify/suite"
	"testing"
)

type ModuleSuite struct {
	testsuite.TestSuite
}

func TestModuleSuite(t *testing.T) {
	ts, err := testsuite.New()
	if err != nil {
		t.Errorf("failed to intialise new testsuite: %+v", err)
	}

	as := &ModuleSuite{
		TestSuite: *ts,
	}

	suite.Run(t, as)
}
