package models_test

import (
	"database/sql"
	"github.com/dokedu/dokedu-api-beta/services/internal/testsuite"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"github.com/stretchr/testify/suite"
	"testing"
)

type ModelSuite struct {
	testsuite.TestSuite
}

func TestModelSuite(t *testing.T) {
	ts, err := testsuite.New()
	if err != nil {
		t.Errorf("failed to intialise new testsuite: %+v", err)
	}

	as := &ModelSuite{
		TestSuite: *ts,
	}

	suite.Run(t, as)
}

// for the trigger tests: we should not use the delete function from bun, since that has soft_delete built in
func (s *ModelSuite) Test_SoftDelete_Trigger() {
	_, _, acc := s.Seed().UserWithOrg()
	s.False(acc.DeletedAt.Valid)

	// delete account
	_, err := s.DB.Exec("delete from accounts where id = ?", acc.ID)
	s.NoError(err)

	// check account is soft deleted
	err = s.DB.NewSelect().Model(&acc).Where("id = ?", acc.ID).WhereAllWithDeleted().Scan(s.Context())
	s.NoError(err)
	s.True(acc.DeletedAt.Valid)
}

// when setting hard_delete is set to on, the model will be hard deleted
func (s *ModelSuite) Test_SoftDelete_Trigger_HardDelete() {
	_, _, acc := s.Seed().UserWithOrg()
	s.False(acc.DeletedAt.Valid)

	// new tx
	tx, err := s.DB.NewTx(s.Context(), nil)
	s.NoError(err)

	_, err = tx.Exec("set local app.hard_delete='on';")
	s.NoError(err)

	// delete account
	_, err = tx.Exec("delete from accounts where id = ?", acc.ID)
	s.NoError(err)

	err = tx.Commit()
	s.NoError(err)

	// check account is hard deleted
	err = s.DB.NewSelect().Model(&acc).Where("id = ?", acc.ID).Scan(s.Context())
	s.ErrorIs(err, sql.ErrNoRows)
}

// identity helpers respect deleted_at
func (s *ModelSuite) Test_SoftDelete_IdentityHelper() {
	_, _, acc := s.Seed().UserWithOrg()

	// get identity
	s.True(acc.IdentityID.Valid)
	var identity models.Identity
	err := s.DB.NewSelect().Model(&identity).Where("id = ?", acc.IdentityID.String).Scan(s.Context())
	s.NoError(err)

	// new tx
	tx, err := s.DB.NewTx(s.Context(), nil)
	s.NoError(err)

	err = tx.SetUser(identity.UserID)
	s.NoError(err)

	// get users account_ids
	var accountIDs []string
	res, err := tx.Query("select identity_account_ids()")
	s.NoError(err)
	for res.Next() {
		var accountID string
		err = res.Scan(&accountID)
		s.NoError(err)
		accountIDs = append(accountIDs, accountID)
	}
	s.NoError(err)
	s.Len(accountIDs, 1)

	// delete account
	_, err = tx.Exec("delete from accounts where id = ?", acc.ID)
	s.NoError(err)

	// check account is soft deleted
	accountIDs = []string{}
	res, err = tx.Query("select identity_account_ids()")
	s.NoError(err)
	for res.Next() {
		var accountID string
		err = res.Scan(&accountID)
		s.NoError(err)
		accountIDs = append(accountIDs, accountID)
	}
	s.NoError(err)
	s.Len(accountIDs, 0)
}
