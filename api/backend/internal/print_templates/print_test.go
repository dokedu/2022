package print_templates_test

import (
	"github.com/dokedu/dokedu-api-beta/services/internal/print_templates"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"github.com/stretchr/testify/assert"
	"testing"
	"time"
)

func Test_RenderHeader(t *testing.T) {
	pt, err := print_templates.New()
	assert.NoError(t, err)

	header, err := pt.RenderHeader(print_templates.HeaderData{
		PageType: "test",
		Date: print_templates.HeaderDataDate{
			Today: time.Now(),
			From:  time.Now().AddDate(-1, 0, 0),
			To:    time.Now().AddDate(1, 0, 0),
		},
		Student: models.Account{
			FirstName: "first",
			LastName:  "last",
		},
	})
	assert.NoError(t, err)
	assert.NotEmpty(t, header)

	headerS := string(header)
	assert.Contains(t, headerS, "first")
	assert.Contains(t, headerS, "last")

}

func Test_RenderReport(t *testing.T) {
	pt, err := print_templates.New()
	assert.NoError(t, err)

	content, err := pt.RenderReport(print_templates.ReportContentData{Entries: []print_templates.ReportDataEntry{
		{
			ID:   "aa",
			Date: time.Now(),
			Body: "{}",
			Competences: []print_templates.DataCompetence{
				{
					Name:  "Test",
					Level: 5,
				},
			},
			Account: models.Account{
				FirstName: "Felix",
				LastName:  "Hromadko",
			},
			Tags: []string{"TestTestTestTestTestTest TestTestTestTestTestTestTest TestTestTestTestTestTestTest TestTestTestTestTestTestTest Test", "Garden", "Water", "Yay"},
		},
	}})
	assert.NoError(t, err)
	assert.NotEmpty(t, content)

	assert.Contains(t, string(content), "Felix")

	//For development purposes:
	//file, err := os.CreateTemp(os.TempDir(), "report_*.html")
	//assert.NoError(t, err)
	//
	//_, err = file.Write(content)
	//assert.NoError(t, err)
	//
	//fmt.Println(file.Name())
}
