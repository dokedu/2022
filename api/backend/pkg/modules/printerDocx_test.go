package modules_test

import (
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"time"
)

func (ms *ModuleSuite) Test_Printer_HandleNewReport_DocxReport() {
	uid, o, a := ms.Seed().UserWithOrg()
	competences := ms.Seed().Competences(o.ID)
	event := ms.Seed().CreateEvent(o.ID, "TestEvent", competences[25:35])
	event2 := ms.Seed().CreateEvent(o.ID, "2event2", nil)
	_, tagIDs := ms.Seed().Tags(uid, o.ID, a.ID)

	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[20:21], nil)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, nil, nil)
	entry, _ := ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[20:30], nil)

	ms.Seed().CreateEntryEvent(entry.ID, event.ID)
	ms.Seed().CreateEntryEvent(entry.ID, event2.ID)
	ms.Seed().CreateEntryTag(o.ID, entry.ID, tagIDs[0])
	ms.Seed().CreateEntryTag(o.ID, entry.ID, tagIDs[1])

	// create new report
	report := models.Report{
		Status:           models.ReportStatusPending,
		Type:             models.ReportTypeDocx,
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

func (ms *ModuleSuite) Test_Printer_HandleNewReport_DocxSubject() {
	uid, o, a := ms.Seed().UserWithOrg()
	competences := ms.Seed().Competences(o.ID)
	event := ms.Seed().CreateEvent(o.ID, "TestEvent", competences[25:35])
	event2 := ms.Seed().CreateEvent(o.ID, "2event2", nil)
	_, tagIDs := ms.Seed().Tags(uid, o.ID, a.ID)

	ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[20:21], nil)
	ms.Seed().CreateEntryAccount(o.ID, a.ID, nil, nil)
	entry, _ := ms.Seed().CreateEntryAccount(o.ID, a.ID, competences[20:30], nil)

	ms.Seed().CreateEntryEvent(entry.ID, event.ID)
	ms.Seed().CreateEntryEvent(entry.ID, event2.ID)
	ms.Seed().CreateEntryTag(o.ID, entry.ID, tagIDs[0])
	ms.Seed().CreateEntryTag(o.ID, entry.ID, tagIDs[1])

	// create new report
	report := models.Report{
		Status:           models.ReportStatusPending,
		Type:             models.ReportTypeDocxSubjects,
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
