package cache

// has some often used build dependencies cached
import (
	_ "github.com/fatih/color"
	_ "github.com/go-rod/rod"
	_ "github.com/golang-jwt/jwt"
	_ "github.com/joho/godotenv"
	_ "github.com/labstack/echo/v4"
	_ "github.com/labstack/echo/v4/middleware"
	_ "github.com/labstack/gommon/random"
	_ "github.com/meilisearch/meilisearch-go"
	_ "github.com/sirupsen/logrus"
	_ "github.com/uptrace/bun"
	_ "github.com/uptrace/bun/migrate"
	_ "github.com/urfave/cli/v2"
	_ "golang.org/x/crypto/bcrypt"
	_ "mellium.im/sasl"
)
