package print_templates

import (
	"bytes"
	"embed"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"html/template"
	"time"
)

//go:embed *.gohtml
var templates embed.FS

type PrintTemplate struct {
	Template *template.Template
}

func New() (PrintTemplate, error) {
	t, err := template.New("footer.gohtml").
		Funcs(template.FuncMap{
			"formatDate": func(date time.Time) string {
				return date.Format("02.01.2006")
			},
			"iterate": func(to int) []int {
				var result []int
				for i := 0; i < to; i++ {
					result = append(result, i)
				}
				return result
			},
		}).
		ParseFS(templates, "*.gohtml")
	if err != nil {
		return PrintTemplate{}, err
	}

	return PrintTemplate{Template: t}, nil
}

type ReportData struct {
	HeaderData  HeaderData
	ContentData ReportContentData
}
type HeaderData struct {
	PageType string         `json:"page_type"`
	Date     HeaderDataDate `json:"date"`
	Student  models.Account `json:"student"`
}

type HeaderDataDate struct {
	Today time.Time `json:"today"`
	From  time.Time `json:"from"`
	To    time.Time `json:"to"`
}

type SubjectsData struct {
	HeaderData  HeaderData
	ContentData SubjectContentData
}

type SubjectContentData struct {
	Subjects []SubjectContentDataSubject `json:"subjects"`
}

type SubjectContentDataSubject struct {
	Name        string           `json:"name"`
	Competences []DataCompetence `json:"competences"`
}

func (pt *PrintTemplate) RenderHeader(data HeaderData) ([]byte, error) {
	var out bytes.Buffer

	err := pt.Template.ExecuteTemplate(&out, "header.gohtml", data)
	if err != nil {
		return nil, err
	}

	return out.Bytes(), nil
}

func (pt *PrintTemplate) RenderFooter(data HeaderData) ([]byte, error) {
	var out bytes.Buffer

	err := pt.Template.ExecuteTemplate(&out, "footer.gohtml", data)
	if err != nil {
		return nil, err
	}

	return out.Bytes(), nil
}

type ReportContentData struct {
	Entries []ReportDataEntry
}

type ReportDataEntry struct {
	ID          string
	Date        time.Time
	Body        string
	Competences []DataCompetence
	Tags        []string
	Account     models.Account
}

type DataCompetence struct {
	Name  string `json:"name"`
	Level int    `json:"level"`
}

func (pt *PrintTemplate) RenderReport(data ReportContentData) ([]byte, error) {
	var out bytes.Buffer

	err := pt.Template.ExecuteTemplate(&out, "report.gohtml", data)
	if err != nil {
		return nil, err
	}

	return out.Bytes(), nil
}

func (pt *PrintTemplate) RenderSubjects(data SubjectContentData) ([]byte, error) {
	var out bytes.Buffer

	err := pt.Template.ExecuteTemplate(&out, "subject.gohtml", data)
	if err != nil {
		return nil, err
	}

	return out.Bytes(), nil
}
