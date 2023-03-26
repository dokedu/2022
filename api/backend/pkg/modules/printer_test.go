package modules_test

import (
	"github.com/dokedu/dokedu-api-beta/services/internal/print_templates"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"time"
)

func (ms *ModuleSuite) Test_Printer_PrintReport() {
	_, err := ms.Modules.Printer.PrintReport(print_templates.ReportData{
		HeaderData: print_templates.HeaderData{
			PageType: "Report",
			Date: print_templates.HeaderDataDate{
				Today: time.Now(),
				From:  time.Now().AddDate(-1, 0, 0),
				To:    time.Now(),
			},
			Student: models.Account{
				FirstName: "Felix",
				LastName:  "Hromadko",
			},
		},
		ContentData: print_templates.ReportContentData{
			Entries: []print_templates.ReportDataEntry{
				{
					ID:   "a",
					Date: time.Time{},
					Body: "{\"type\": \"doc\",\"content\": [{\"type\": \"paragraph\",\"content\": [{\"text\": \"this is a test!\",\"type\": \"text\"}]}]}",
					Competences: []print_templates.DataCompetence{
						{
							Name:  "Test",
							Level: 1,
						},
					},
					Account: models.Account{
						FirstName: "tom",
						LastName:  "Hart",
					},
				},
			},
		},
	},
	)

	ms.NoError(err)
}

func (ms *ModuleSuite) Test_Printer_PrintSubject() {
	_, err := ms.Modules.Printer.PrintSubjects(print_templates.SubjectsData{
		HeaderData: print_templates.HeaderData{
			PageType: "Report",
			Date: print_templates.HeaderDataDate{
				Today: time.Now(),
				From:  time.Now().AddDate(-1, 0, 0),
				To:    time.Now(),
			},
			Student: models.Account{
				FirstName: "Felix",
				LastName:  "Hromadko",
			},
		},
		ContentData: print_templates.SubjectContentData{
			Subjects: []print_templates.SubjectContentDataSubject{
				{
					Name: "Deutsch",
					Competences: []print_templates.DataCompetence{
						{
							Name:  "Test",
							Level: 1,
						},
						{
							Name:  "Test2",
							Level: 2,
						},
					},
				},
				{
					Name: "Netzwerktechnik",
					Competences: []print_templates.DataCompetence{
						{
							Name:  "Switches konfigurieren",
							Level: 3,
						},
						{
							Name:  "Patchkabel herstellen",
							Level: 1,
						},
					},
				},
			},
		},
	})
	ms.NoError(err)
}

func (ms *ModuleSuite) Test_Printer_HandleNewReport_Report() {
	_, o, a := ms.Seed().UserWithOrg()
	competences := ms.Seed().Competences(o.ID)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[20:21], nil)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, nil, nil)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[20:40], nil)

	// create new report
	report := models.Report{
		Status:           models.ReportStatusPending,
		Type:             models.ReportTypeReport,
		AccountID:        a.ID,
		Account:          &a,
		StudentAccountID: a.ID,
		From:             time.Now().AddDate(-1, 0, 0),
		To:               time.Now(),
	}
	_, err := ms.DB.NewInsert().Model(&report).Exec(ms.Context())
	ms.NoError(err)

	// notify printer
	err = ms.Modules.Printer.HandleNewReport(report)
	ms.NoError(err)
}
func (ms *ModuleSuite) Test_Printer_HandleNewReport_Report_WithEvent() {
	_, o, a := ms.Seed().UserWithOrg()
	competences := ms.Seed().Competences(o.ID)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[20:21], nil)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, nil, nil)
	entry, _ := ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[40:42], nil)
	event := ms.Seed().CreateEvent(o.ID, "TestEvent", competences[40:50])
	ms.Seed().CreateEntryEvent(entry.ID, event.ID)

	// create new report
	report := models.Report{
		Status:           models.ReportStatusPending,
		Type:             models.ReportTypeReport,
		AccountID:        a.ID,
		Account:          &a,
		StudentAccountID: a.ID,
		From:             time.Now().AddDate(-1, 0, 0),
		To:               time.Now(),
	}
	_, err := ms.DB.NewInsert().Model(&report).Exec(ms.Context())
	ms.NoError(err)

	// notify printer
	err = ms.Modules.Printer.HandleNewReport(report)
	ms.NoError(err)
}

func (ms *ModuleSuite) Test_Printer_HandleNewReport_Subject() {
	_, o, a := ms.Seed().UserWithOrg()
	competences := ms.Seed().Competences(o.ID)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[22:23], nil)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, nil, nil)
	entry, _ := ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[40:42], nil)
	event := ms.Seed().CreateEvent(o.ID, "TestEvent", competences[40:50])
	ms.Seed().CreateEntryEvent(entry.ID, event.ID)

	// create new report
	report := models.Report{
		Status:           models.ReportStatusPending,
		Type:             models.ReportTypeSubjects,
		AccountID:        a.ID,
		Account:          &a,
		StudentAccountID: a.ID,
		From:             time.Now().AddDate(-1, 0, 0),
		To:               time.Now(),
	}
	_, err := ms.DB.NewInsert().Model(&report).Exec(ms.Context())
	ms.NoError(err)

	// notify printer
	err = ms.Modules.Printer.HandleNewReport(report)
	ms.NoError(err)
}

func (ms *ModuleSuite) Test_Printer_HandleNewReport_Subject_Today() {
	_, o, a := ms.Seed().UserWithOrg()
	competences := ms.Seed().Competences(o.ID)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[22:23], nil)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, nil, nil)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[22:40], nil)

	// create new subject
	report := models.Report{
		Status:           models.ReportStatusPending,
		Type:             models.ReportTypeSubjects,
		AccountID:        a.ID,
		Account:          &a,
		StudentAccountID: a.ID,
		From:             time.Now(),
		To:               time.Now(),
	}
	_, err := ms.DB.NewInsert().Model(&report).Exec(ms.Context())
	ms.NoError(err)

	// notify printer
	err = ms.Modules.Printer.HandleNewReport(report)
	ms.NoError(err)
}

func (ms *ModuleSuite) Test_Printer_HandleNewReport_AsyncTrigger() {
	userID, o, a := ms.Seed().UserWithOrg()
	competences := ms.Seed().Competences(o.ID)
	_, tagIDs := ms.Seed().Tags(userID, o.ID, a.ID)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[0:3], tagIDs[:])
	ms.Seed().CreateEntryAccount(o.ID, a.ID, nil, tagIDs[:])
	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[0:10], nil)

	// create new report
	report := models.Report{
		Status:           models.ReportStatusPending,
		Type:             models.ReportTypeReport,
		AccountID:        a.ID,
		Account:          &a,
		StudentAccountID: a.ID,
		From:             time.Now().AddDate(-1, 0, 0),
		To:               time.Now(),
		FilterTags:       tagIDs,
	}
	_, err := ms.DB.NewInsert().Model(&report).Exec(ms.Context())
	ms.NoError(err)

	// wait for a bit.
	time.Sleep(15 * time.Second)

	err = ms.DB.NewSelect().Model(&report).Where("id = ?", report.ID).Scan(ms.Context())
	ms.NoError(err)

	ms.Equal(models.ReportStatusDone, report.Status)
}

func (ms *ModuleSuite) Test_Printer_FetchEntriesForReportTypeReport_RespectsTags() {
	userID, o, a := ms.Seed().UserWithOrg()
	competences := ms.Seed().Competences(o.ID)
	_, tagIDs := ms.Seed().Tags(userID, o.ID, a.ID)

	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[0:3], nil)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[0:3], nil)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[0:3], tagIDs[:1])
	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[0:3], tagIDs[:1])
	e1, _ := ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[0:3], tagIDs[:2])
	e2, _ := ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[0:3], tagIDs[:2])
	e3, _ := ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[0:3], tagIDs[1:3])
	e4, _ := ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[0:3], tagIDs)

	report := models.Report{
		Type:             models.ReportTypeReport,
		FilterTags:       nil,
		StudentAccountID: a.ID,
		From:             time.Now().AddDate(-1, 0, 0),
		To:               time.Now().AddDate(1, 0, 0),
	}

	// with no filter applied, the function should return all entries
	entries, err := ms.Modules.Printer.FetchEntriesForReportTypeReport(ms.Context(), report)
	ms.NoError(err)
	ms.Len(entries, 8)

	// with just the first tagID selected, it should only return 5 entries
	report.FilterTags = tagIDs[0:1]
	entries, err = ms.Modules.Printer.FetchEntriesForReportTypeReport(ms.Context(), report)
	ms.NoError(err)
	ms.Len(entries, 5)

	// with all tags selected, it should only return e4
	report.FilterTags = tagIDs
	entries, err = ms.Modules.Printer.FetchEntriesForReportTypeReport(ms.Context(), report)
	ms.NoError(err)
	ms.Len(entries, 1)
	ms.Equal(entries[0].ID, e4.ID)

	// for the 2nd tag, e1-e4 should be returned
	report.FilterTags = tagIDs[1:2]
	entries, err = ms.Modules.Printer.FetchEntriesForReportTypeReport(ms.Context(), report)

	entryIds := make([]string, len(entries))
	for i, entry := range entries {
		entryIds[i] = entry.ID
	}

	ms.NoError(err)
	ms.Len(entries, 4)
	ms.Contains(entryIds, e1.ID)
	ms.Contains(entryIds, e2.ID)
	ms.Contains(entryIds, e3.ID)
	ms.Contains(entryIds, e4.ID)
}

// when the same competence was documented multiple times, we only return the level of the last entry.
func (ms *ModuleSuite) Test_Printer_FetchEntriesForReportTypeReport_DuplicateOrder() {
	_, o, a := ms.Seed().UserWithOrg()
	competences := ms.Seed().Competences(o.ID)
	ms.Seed().CreateEntryAccountCompetence(a.ID, competences[21].ID, 1)
	ms.Seed().CreateEntryAccountCompetence(a.ID, competences[21].ID, 3)
	ms.Seed().CreateEntryAccountCompetence(a.ID, competences[21].ID, 2)

	ms.Seed().CreateEntryAccountCompetence(a.ID, competences[26].ID, 1)
	ms.Seed().CreateEntryAccountCompetence(a.ID, competences[26].ID, 3)
	ms.Seed().CreateEntryAccountCompetence(a.ID, competences[26].ID, 0)

	ms.Seed().CreateEntryAccountCompetence(a.ID, competences[22].ID, 3)
	ms.Seed().CreateEntryAccountCompetence(a.ID, competences[22].ID, 0)
	ms.Seed().CreateEntryAccountCompetence(a.ID, competences[22].ID, 1)

	_, res, err := ms.Modules.Printer.FetchDataForReportSubjects(models.Report{
		AccountID:        a.ID,
		StudentAccountID: a.ID,
		From:             time.Now().AddDate(0, 0, -1),
		To:               time.Now().AddDate(0, 0, 1),
	})
	ms.NoError(err)

	ms.Len(res, 2)
	ms.Equal("subject 2", res[0].Name)
	ms.Equal("subject 3", res[1].Name)
	ms.Len(res[0].Competences, 2)
	ms.Len(res[1].Competences, 1)

	ms.Equal(competences[21].Name, res[0].Competences[0].Name)
	ms.Equal(competences[26].Name, res[0].Competences[1].Name)

	ms.Equal(2, res[0].Competences[0].Level)
	ms.Equal(0, res[0].Competences[1].Level)

	ms.Equal(competences[22].Name, res[1].Competences[0].Name)
	ms.Equal(1, res[1].Competences[0].Level)
}
