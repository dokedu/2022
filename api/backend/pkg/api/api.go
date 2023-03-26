package api

import (
	"fmt"
	"github.com/dokedu/dokedu-api-beta/services/pkg/api/middlewares"
	"github.com/dokedu/dokedu-api-beta/services/pkg/db"
	"github.com/dokedu/dokedu-api-beta/services/pkg/jwt"
	"github.com/dokedu/dokedu-api-beta/services/pkg/modules"
	"github.com/go-playground/validator/v10"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

type Api struct {
	*echo.Echo
	db        *db.DB
	JwtSigner jwt.Signer
	config    Config
}

type Config struct {
	Host             string
	Port             string
	JwtSecret        string
	AllowedOrigins   []string
	Debug            bool
	ValidateRequests bool
	Environment      ApiEnvironment
}

type ApiEnvironment string

var (
	ApiEnvironmentDevelopment ApiEnvironment = "development"
	ApiEnvironmentProduction  ApiEnvironment = "production"
)

func New(cfg Config, db *db.DB, mods *modules.Modules) *Api {
	e := echo.New()
	jwtSigner := jwt.NewSigner(cfg.JwtSecret)

	e.Validator = &CustomValidator{validator: validator.New()}
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: cfg.AllowedOrigins,
		AllowHeaders: []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAccept, echo.HeaderAuthorization},
	}))
	e.Use(middlewares.Context)
	e.Use(middlewares.Auth(jwtSigner))

	//if cfg.ValidateRequests {
	//	e.Use(validation)
	//}

	e.Use(middlewares.Transaction(db))
	e.Use(middlewares.ErrorHandler())

	e.GET("/", func(c echo.Context) error {
		return c.String(http.StatusOK, "Hello, World!")
	})

	e.POST("/meili/reset", ResetIndex(mods), middlewares.AuthGuard())
	e.POST("/meili/indexes/:id/search", SearchMeili(mods), middlewares.AuthGuard())
	e.POST("/auth/invite", InviteUser(mods), middlewares.AuthGuard())

	if cfg.Environment == ApiEnvironmentDevelopment {
		e.POST("/auth/init_account", InitAccount, middlewares.AuthGuard())
		e.POST("/auth/init_identity", InitIdentity, middlewares.AuthGuard())
	}

	return &Api{
		Echo:      e,
		config:    cfg,
		db:        db,
		JwtSigner: jwtSigner,
	}
}

func (a *Api) Start() error {
	if err := a.Echo.Start(fmt.Sprintf(":%s", a.config.Port)); err != nil {
		return fmt.Errorf("could not start api: %w", err)
	}

	return nil
}
