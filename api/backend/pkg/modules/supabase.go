package modules

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"io"
	"net/http"
)

type SupabaseModule struct {
	Cfg SupabaseModuleConfig
}

type SupabaseModuleConfig struct {
	SupabaseBaseURL        string
	SupabaseServiceRoleKey string
}

func NewSupabaseModule(cfg SupabaseModuleConfig) *SupabaseModule {
	return &SupabaseModule{
		Cfg: cfg,
	}
}

func (m *SupabaseModule) UploadFile(orgID string, fileKey string, fileContent io.Reader, contentType string) error {
	req, err := http.NewRequest(http.MethodPost, fmt.Sprintf("%s/storage/v1/object/org_%s/%s", m.Cfg.SupabaseBaseURL, orgID, fileKey), fileContent)
	if err != nil {
		return err
	}

	req.Header.Set("Content-Type", contentType)
	req.Header.Set("apikey", m.Cfg.SupabaseServiceRoleKey)
	req.Header.Set("Authorization", "Bearer "+m.Cfg.SupabaseServiceRoleKey)
	req.Header.Set("x-upsert", "true")

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}

	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code: %d", res.StatusCode)
	}

	return nil
}

func mapToJson(data map[string]interface{}) (io.Reader, error) {
	str, err := json.Marshal(data)
	if err != nil {
		return nil, err
	}

	return bytes.NewReader(str), nil
}

func (m *SupabaseModule) InviteUserByEmail(email string) (models.User, error) {
	payload, err := mapToJson(map[string]interface{}{
		"email": email,
	})

	if err != nil {
		return models.User{}, err
	}

	req, err := http.NewRequest(http.MethodPost, fmt.Sprintf("%s/auth/v1/invite", m.Cfg.SupabaseBaseURL), payload)
	if err != nil {
		return models.User{}, err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", m.Cfg.SupabaseServiceRoleKey)
	req.Header.Set("Authorization", "Bearer "+m.Cfg.SupabaseServiceRoleKey)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return models.User{}, err
	}

	if res.StatusCode != http.StatusOK {
		return models.User{}, fmt.Errorf("unexpected status code: %d", res.StatusCode)
	}

	var user models.User
	err = json.NewDecoder(res.Body).Decode(&user)
	if err != nil {
		return models.User{}, err
	}

	return user, nil
}
