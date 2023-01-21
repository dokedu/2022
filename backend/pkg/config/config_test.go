package config_test

import (
	"github.com/dokedu/dokedu-api-beta/services/pkg/config"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestLoad(t *testing.T) {
	cfg, err := config.Load()
	assert.NoError(t, err)

	dbCfg := cfg.DBConfig
	assert.NotEmpty(t, dbCfg.Port)
	assert.NotEmpty(t, dbCfg.Host)
	assert.NotEmpty(t, dbCfg.Database)
	assert.NotEmpty(t, dbCfg.Password)
	assert.NotEmpty(t, dbCfg.Username)
}
