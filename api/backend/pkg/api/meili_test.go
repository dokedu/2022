package api_test

import (
	"fmt"
	"github.com/uptrace/bun"
	"strings"
	"time"
)

// returns 401 on unauthenticated requests
func (as *ApiSuite) Test_MeiliSearch_Unauthenticated() {
	res := as.Request("POST", "/meili/indexes/abc/search", nil, "")
	as.Equal(401, res.Code)
}

// returns 403 on authenticated requests from different organisations
func (as *ApiSuite) Test_MeiliSearch_DifferentOrganisation() {
	u1, org1, _ := as.Seed().UserWithOrg()
	u2, org2, _ := as.Seed().UserWithOrg()

	res := as.Request("POST", fmt.Sprintf("/meili/indexes/%s/search", org1.ID), nil, u2)
	as.Equal(403, res.Code)

	res = as.Request("POST", fmt.Sprintf("/meili/indexes/%s/search", org2.ID), nil, u1)
	as.Equal(403, res.Code)
}

// returns 200 on authenticated and valid requests
func (as *ApiSuite) Test_MeiliSearch() {
	u1, org1, _ := as.Seed().UserWithOrg()

	// prepare competences
	as.Seed().Competences(org1.ID)

	// make sure index is initialized
	res := as.Request("POST", fmt.Sprintf("/meili/reset?organisation_id=%s", org1.ID), nil, u1)
	as.Equal(200, res.Code)
	time.Sleep(250 * time.Millisecond)

	res = as.Request("POST", fmt.Sprintf("/meili/indexes/%s/search", org1.ID), map[string]string{
		"q": "thisisdefinitelyanexamplequery",
	}, u1)
	as.Equal(200, res.Code)

	var data map[string]interface{}
	as.BindResponse(res, &data)

	as.IsType([]interface{}{}, data["hits"])
	as.Len(data["hits"], 0)

	res = as.Request("POST", fmt.Sprintf("/meili/indexes/%s/search", org1.ID), map[string]string{
		"q": "group 1",
	}, u1)
	as.Equal(200, res.Code)
	as.BindResponse(res, &data)

	as.IsType([]interface{}{}, data["hits"])
	as.Len(data["hits"], 20)

	// includes some competences
	// data should not include any competences
	found := false
	for _, hit := range data["hits"].([]interface{}) {
		if strings.Contains(hit.(map[string]interface{})["name"].(string), "competence") {
			found = true
		}
	}
	as.True(found)

	//should include grades and competence_id
	as.NotEmpty(data["hits"].([]interface{})[0].(map[string]interface{})["competence_id"])
	as.NotEmpty(data["hits"].([]interface{})[0].(map[string]interface{})["grades"])
	as.Empty(data["hits"].([]interface{})[0].(map[string]interface{})["somerandomstring"])
}

// returns 200 on authenticated and valid requests
func (as *ApiSuite) Test_MeiliSearch_DeletedCompetences() {
	u1, org1, _ := as.Seed().UserWithOrg()

	// prepare competences
	competences := as.Seed().Competences(org1.ID)

	cids := make([]string, 30)
	for i := 20; i < 50; i++ {
		cids[i-20] = competences[i].ID
	}

	// mark competences as deleted
	_, err := as.DB.NewUpdate().Table("competences").Set("deleted_at = ?", time.Now()).Where("id IN (?)", bun.In(cids)).Exec(as.Context())
	as.NoError(err)

	// make sure index is initialized
	res := as.Request("POST", fmt.Sprintf("/meili/reset?organisation_id=%s", org1.ID), nil, u1)
	as.Equal(200, res.Code)
	time.Sleep(250 * time.Millisecond)

	//should not find anything
	res = as.Request("POST", fmt.Sprintf("/meili/indexes/%s/search", org1.ID), map[string]string{
		"q": "group 1",
	}, u1)
	as.Equal(200, res.Code)
	var data map[string]interface{}
	as.BindResponse(res, &data)

	as.IsType([]interface{}{}, data["hits"])

	// data should not include any competences
	found := false
	for _, hit := range data["hits"].([]interface{}) {
		if strings.Contains(hit.(map[string]interface{})["name"].(string), "competence") {
			found = true
		}
	}
	as.False(found)
}

// returns 401 on unauthenticated requests
func (as *ApiSuite) Test_MeiliSearch_Reset_Unauthenticated() {
	res := as.Request("POST", "/meili/reset", nil, "")
	as.Equal(401, res.Code)
}

// returns 403 on authenticated requests from different organisations
func (as *ApiSuite) Test_MeiliSearch_Reset_DifferentOrganisation() {
	u1, org1, _ := as.Seed().UserWithOrg()
	u2, org2, _ := as.Seed().UserWithOrg()

	res := as.Request("POST", fmt.Sprintf("/meili/reset?organisation_id=%s", org1.ID), nil, u2)
	as.Equal(403, res.Code)

	res = as.Request("POST", fmt.Sprintf("/meili/reset?organisation_id=%s", org2.ID), nil, u1)
	as.Equal(403, res.Code)
}

// returns 200 on authenticated requests from the same organisation
func (as *ApiSuite) Test_MeiliSearch_Reset() {
	u1, org1, _ := as.Seed().UserWithOrg()

	res := as.Request("POST", fmt.Sprintf("/meili/reset?organisation_id=%s", org1.ID), nil, u1)
	as.Equal(200, res.Code)
}

// 403 on soft-deleted accounts
func (as *ApiSuite) Test_MeiliSearch_Rest_SoftDelete() {
	u1, org1, a1 := as.Seed().UserWithOrg()

	_, err := as.DB.NewDelete().Table("accounts").Where("id = ?", a1.ID).Exec(as.Context())
	as.NoError(err)

	res := as.Request("POST", fmt.Sprintf("/meili/reset?organisation_id=%s", org1.ID), nil, u1)
	as.Equal(403, res.Code)
}
