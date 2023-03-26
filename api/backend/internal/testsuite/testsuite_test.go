package testsuite

import (
	"testing"

	"github.com/stretchr/testify/suite"
)

func TestTestSuite(t *testing.T) {
	ts, err := New()
	if err != nil {
		t.Errorf("failed to intialise new testsuite: %+v", err)
	}

	suite.Run(t, ts)
}
