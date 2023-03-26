package api

import (
	"database/sql"
	"errors"
	"github.com/dokedu/dokedu-api-beta/services/pkg/api/status"
	"github.com/dokedu/dokedu-api-beta/services/pkg/helper"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"github.com/dokedu/dokedu-api-beta/services/pkg/modules"
	"github.com/labstack/echo/v4"
	"net/http"
)

type InviteUserRequest struct {
	Email          string `validate:"required,email" json:"email"`
	FirstName      string `validate:"required" json:"first_name"`
	LastName       string `validate:"required" json:"last_name"`
	OrganisationID string `validate:"required" json:"organisation_id"`
	Role           string `validate:"required,oneof=admin teacher teacher_guest" json:"role"`
}

func InviteUser(mods *modules.Modules) func(c echo.Context) error {
	return func(c echo.Context) error {
		ctx := c.(helper.ApiContext)

		var req InviteUserRequest
		if err := ctx.Bind(&req); err != nil {
			return echo.NewHTTPError(http.StatusBadRequest, status.ErrBadRequest)
		}

		// validate request
		if err := ctx.Validate(req); err != nil {
			return echo.NewHTTPError(http.StatusBadRequest, status.ErrBadRequest)
		}

		// check if user is admin or owner in the organisation
		cnt, err := ctx.Tx.NewSelect().
			TableExpr("accounts a").
			Join("inner join identities i on i.id = a.identity_id").
			Where("i.user_id = ?", ctx.Claims.Sub).
			Where("a.organisation_id = ?", req.OrganisationID).
			Where("a.role = 'admin' or role = 'owner'").
			Where("a.deleted_at IS NULL").
			Where("i.deleted_at IS NULL").
			Count(ctx.Request().Context())

		if err != nil {
			return err
		}

		if cnt != 1 {
			return echo.NewHTTPError(http.StatusForbidden, status.ErrForbidden)
		}

		// check if user already exists
		var user models.User
		err = ctx.Tx.NewSelect().
			TableExpr("\"auth\".users").
			Column("id", "email").
			Where("email = ?", req.Email).
			Scan(ctx.Request().Context(), &user)

		if errors.Is(err, sql.ErrNoRows) {
			user, err = mods.Supabase.InviteUserByEmail(req.Email)
			if err != nil {
				return err
			}
		} else if err != nil {
			return err
		}

		// check if the user has an identity already
		var identity models.Identity
		err = ctx.Tx.NewSelect().
			Model(&identity).
			Where("user_id = ?", user.ID).
			Where("deleted_at IS NULL").
			Scan(ctx.Request().Context())
		if err != nil {
			if !errors.Is(err, sql.ErrNoRows) {
				return err
			}

			// create identity
			identity.UserID = user.ID
			identity.GlobalRole = "default"

			_, err = ctx.Tx.NewInsert().
				Model(&identity).
				Exec(ctx.Request().Context())
			if err != nil {
				return err
			}
		}

		// check if account already exists
		cnt, err = ctx.Tx.NewSelect().
			Table("accounts").
			Where("identity_id = ?", identity).
			Where("organisation_id = ?", req.OrganisationID).
			Where("deleted_at IS NULL").
			Count(ctx.Request().Context())
		if err != nil {
			return err
		}

		if cnt != 0 {
			return echo.NewHTTPError(http.StatusConflict, "user already part of organisation")
		}

		// create account
		account := models.Account{
			IdentityID: sql.NullString{
				String: identity.ID,
				Valid:  true,
			},
			OrganisationID: req.OrganisationID,
			Role:           req.Role,
			FirstName:      req.FirstName,
			LastName:       req.LastName,
		}
		_, err = ctx.Tx.NewInsert().
			Model(&account).
			Exec(ctx.Request().Context())

		if err != nil {
			return err
		}

		return ctx.JSON(http.StatusOK, status.ResOK)
	}
}
