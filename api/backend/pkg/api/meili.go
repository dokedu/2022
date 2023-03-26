package api

import (
	"github.com/dokedu/dokedu-api-beta/services/pkg/api/status"
	"github.com/dokedu/dokedu-api-beta/services/pkg/helper"
	"github.com/dokedu/dokedu-api-beta/services/pkg/modules"
	"github.com/labstack/echo/v4"
	"net/http"
)

func ResetIndex(mods *modules.Modules) func(c echo.Context) error {
	return func(c echo.Context) error {
		ctx := c.(helper.ApiContext)
		uid := ctx.Claims.Sub

		orgID := c.QueryParam("organisation_id")
		if orgID == "" {
			return c.JSON(http.StatusBadRequest, status.ErrBadRequest)
		}

		var orgs []string
		err := ctx.Tx.NewSelect().ColumnExpr("a.organisation_id").TableExpr("public.identities i").
			Join("INNER JOIN public.accounts a ON a.identity_id = i.id").
			Where("i.user_id = ? and (a.role = 'admin' or a.role = 'owner')", uid).
			Where("a.deleted_at is null and i.deleted_at is null").
			Scan(ctx.Request().Context(), &orgs)
		if err != nil {
			return err
		}

		found := false
		for _, org := range orgs {
			if org == orgID {
				found = true
				break
			}
		}

		if !found {
			return c.JSON(http.StatusForbidden, status.ErrForbidden)
		}

		err = mods.MeiliSearch.ResetIndexForOrganisation(orgID)
		if err != nil {
			return err
		}

		return c.JSON(200, status.ResOK)
	}
}

func SearchMeili(mods *modules.Modules) func(c echo.Context) error {
	return func(c echo.Context) error {
		ctx := c.(helper.ApiContext)

		// get claims uid
		uid := ctx.Claims.Sub

		orgID := c.Param("id")
		if orgID == "" {
			return c.JSON(http.StatusBadRequest, status.ErrBadRequest)
		}

		var orgs []string
		err := ctx.Tx.NewSelect().ColumnExpr("a.organisation_id").TableExpr("public.identities i").
			Join("INNER JOIN public.accounts a ON a.identity_id = i.id").
			Where("i.user_id = ?", uid).
			Where("a.deleted_at is null and i.deleted_at is null").
			Scan(ctx.Request().Context(), &orgs)
		if err != nil {
			return err
		}

		found := false
		for _, org := range orgs {
			if org == orgID {
				found = true
				break
			}
		}

		if !found {
			return c.JSON(http.StatusForbidden, status.ErrForbidden)
		}

		res, err := mods.MeiliSearch.RedirectSearch(orgID, c.Request().Body)
		if err != nil {
			return err
		}

		return c.Stream(res.StatusCode, "application/json", res.Body)
	}
}
