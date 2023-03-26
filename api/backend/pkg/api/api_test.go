package api_test

import (
	"github.com/dokedu/dokedu-api-beta/services/internal/testsuite"
	"testing"

	"github.com/stretchr/testify/suite"
)

type ApiSuite struct {
	testsuite.TestSuite
}

func TestApiSuite(t *testing.T) {
	ts, err := testsuite.New()
	if err != nil {
		t.Errorf("failed to intialise new testsuite: %+v", err)
	}

	as := &ApiSuite{
		TestSuite: *ts,
	}

	suite.Run(t, as)
}
