package api

import (
	"database/sql"
	"errors"
	"fmt"
	"github.com/dokedu/dokedu-api-beta/services/pkg/helper"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"github.com/labstack/echo/v4"
	"net/http"
)

type InitAccountResponse struct {
	IdentityID     string `json:"identity_id"`
	OrganisationID string `json:"organisation_id"`
	AccountID      string `json:"account_id"`
}

func InitAccount(c echo.Context) error {
	ctx := c.(helper.ApiContext)

	var user models.User
	err := ctx.Tx.NewSelect().Table("auth.users").Column("email", "id").Where("id = ?", ctx.Claims.Sub).Scan(c.Request().Context(), &user)
	if err != nil {
		return err
	}

	var identity models.Identity
	err = ctx.Tx.NewSelect().Model(&identity).Where("user_id = ?", user.ID).Scan(c.Request().Context())
	if err == nil {
		return errors.New("identity already exists")
	}

	identity = models.Identity{
		UserID:     user.ID,
		GlobalRole: "default",
	}

	_, err = ctx.Tx.NewInsert().Model(&identity).Returning("id").Exec(c.Request().Context())
	if err != nil {
		return err
	}

	address := models.Address{
		Street:  "Street",
		Zip:     "Zip",
		City:    "City",
		State:   "State",
		Country: "Country",
	}

	_, err = ctx.Tx.NewInsert().Model(&address).Returning("id").Exec(c.Request().Context())
	if err != nil {
		return err
	}

	organisation := models.Organisation{
		Name:      fmt.Sprintf("%s's Organisation", user.Email),
		AddressID: address.ID,
		LegalName: "Legal Name",
		Website:   "Website",
		Phone:     "Phone",
		OwnerID:   identity.ID,
	}

	_, err = ctx.Tx.NewInsert().Model(&organisation).Returning("id").Exec(c.Request().Context())
	if err != nil {
		return err
	}

	account := models.Account{
		Role: "owner",
		IdentityID: sql.NullString{
			String: identity.ID,
			Valid:  true,
		},
		OrganisationID: organisation.ID,
		Organisation:   nil,
		FirstName:      "Max",
		LastName:       "Mustermann",
	}

	_, err = ctx.Tx.NewInsert().Model(&account).Returning("id").Exec(c.Request().Context())
	if err != nil {
		return err
	}

	_, err = ctx.Tx.Exec("insert into storage.buckets (id, name) values (?, ?)", fmt.Sprintf("org_%s", organisation.ID), fmt.Sprintf("org_%s", organisation.ID))
	if err != nil {
		return err
	}

	return ctx.JSON(http.StatusOK, InitAccountResponse{
		IdentityID:     identity.ID,
		OrganisationID: organisation.ID,
		AccountID:      account.ID,
	})
}

type InitIdentityResponse struct {
	IdentityID string `json:"identity_id"`
}

func InitIdentity(c echo.Context) error {
	ctx := c.(helper.ApiContext)

	var user models.User
	err := ctx.Tx.NewSelect().Table("auth.users").Column("email", "id").Where("id = ?", ctx.Claims.Sub).Scan(c.Request().Context(), &user)
	if err != nil {
		return err
	}

	var identity models.Identity
	err = ctx.Tx.NewSelect().Model(&identity).Where("user_id = ?", user.ID).Scan(c.Request().Context())
	if err == nil {
		return errors.New("identity already exists")
	}

	identity = models.Identity{
		UserID:     user.ID,
		GlobalRole: "default",
	}

	_, err = ctx.Tx.NewInsert().Model(&identity).Returning("id").Exec(c.Request().Context())
	if err != nil {
		return err
	}

	return ctx.JSON(http.StatusOK, InitIdentityResponse{
		IdentityID: identity.ID,
	})
}
