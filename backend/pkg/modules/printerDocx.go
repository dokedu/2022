package modules

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"io"
	"os"
	"os/exec"
	"time"
)

type DocxReportDataEntry struct {
	ID          string         `json:"id"`
	CreatedAt   time.Time      `json:"createdAt"`
	CreatedBy   string         `json:"createdBy"`
	Date        time.Time      `json:"date"`
	Description string         `json:"description"`
	Tags        []string       `json:"tags" bun:",array"`
	Events      []string       `json:"events" bun:",array"`
	Competences map[string]int `json:"competences"`
}

func (p *PrinterModule) HandleNewReportTypeDocxReport(report models.Report) (*bytes.Buffer, error) {
	ctx := context.Background()

	var name string
	err := p.DB.NewSelect().Model(&models.Account{}).ColumnExpr("concat(first_name, ' ', last_name)").Where("id=?", report.StudentAccountID).Scan(ctx, &name)
	if err != nil {
		return nil, err
	}

	var entries []DocxReportDataEntry
	res, err := p.DB.QueryContext(ctx, `
select e.id,
       e.created_at,
       e.date,
       e.body as description,
       concat(teacher.first_name, ' ', teacher.last_name) as created_by,
       array_agg(distinct t.name) filter (where t.name is not null) as tags,
       array_agg(distinct ev.title) filter (where ev.title is not null) as events,
       COALESCE(jsonb_object_agg(distinct c2.name, -1) FILTER ( where c2.name is not null), '{}'::jsonb) || jsonb_object_agg(distinct c.name, eac.level) FILTER ( where c.name is not null) as competences
from entries e
         inner join accounts teacher on teacher.id = e.account_id
         inner join entry_accounts ea on e.id = ea.entry_id
         left join entry_tags et on e.id = et.entry_id
         left join tags t on t.id = et.tag_id
         left join entry_events ee on e.id = ee.entry_id
         left join events ev on ee.event_id = ev.id
         left join entry_account_competences eac on e.id = eac.entry_id and eac.account_id = ea.account_id
         left join competences c on eac.competence_id = c.id
		
		left join event_competences ec on ec.event_id = ev.id
		left join competences c2 on c2.id = ec.competence_id
where (ea.account_id = ?)
  and (e.date::date >= ?::date
  and e.date::date <= ?::date)
  and (
    e.deleted_at is null
    and ea.deleted_at is null
    and ee.deleted_at is null
    and eac.deleted_at is null
    and et.deleted_at is null
    and ec.deleted_at is null
    and c2.deleted_at is null
  )
GROUP BY "e"."id", "ea"."account_id", "e"."date", "e"."body", "teacher"."first_name", "teacher"."last_name"
ORDER BY "e"."date" desc`, report.StudentAccountID, report.From, report.To)
	if err != nil {
		return nil, err
	}

	err = p.DB.ScanRows(ctx, res, &entries)
	if err != nil {
		return nil, err
	}

	// write to tmp file
	fIn, err := os.CreateTemp(os.TempDir(), "dokedu_print_*.json")
	if err != nil {
		return nil, err
	}

	fOut, err := os.CreateTemp(os.TempDir(), "dokedu_print_*.docx")
	if err != nil {
		return nil, err
	}

	defer func() {
		_ = fIn.Close()
		_ = fOut.Close()
		_ = os.Remove(fIn.Name())
		_ = os.Remove(fOut.Name())
	}()

	data, err := json.Marshal(map[string]interface{}{
		"studentName": name,
		"entries":     entries,
	})
	if err != nil {
		return nil, err
	}

	if _, err = fIn.Write(data); err != nil {
		return nil, err
	}
	if err = fIn.Close(); err != nil {
		return nil, err
	}

	// invoke node
	// #nosec audit: the arguments DocxExportPath, fIn.Name(), fOut.Name() are not user controlled and cannot be injected.
	cmd := exec.Command("node", fmt.Sprintf("%s/dist/index.js", p.cfg.DocxExportPath), fIn.Name(), fOut.Name())
	err = cmd.Run()
	if err != nil {
		return nil, err
	}

	out, err := io.ReadAll(fOut)
	if err != nil {
		return nil, err
	}

	return bytes.NewBuffer(out), nil
}

type DocxReportDataSubject struct {
	CompetenceName string `json:"competenceName"`
	CompetenceID   string `json:"competenceId"`
	SubjectID      string `json:"subjectId"`
	SubjectName    string `json:"subjectName"`
	Level          int    `json:"level"`
}

func (p *PrinterModule) HandleNewReportTypeDocxSubject(report models.Report) (*bytes.Buffer, error) {
	student, subjects, err := p.FetchDataForReportSubjects(report)
	if err != nil {
		return nil, err
	}

	// write to tmp file
	fIn, err := os.CreateTemp(os.TempDir(), "dokedu_print_*.json")
	if err != nil {
		return nil, err
	}

	fOut, err := os.CreateTemp(os.TempDir(), "dokedu_print_*.docx")
	if err != nil {
		return nil, err
	}

	defer func() {
		_ = fIn.Close()
		_ = fOut.Close()
		_ = os.Remove(fIn.Name())
		_ = os.Remove(fOut.Name())
	}()

	data, err := json.Marshal(map[string]interface{}{
		"studentName": student.FirstName + " " + student.LastName,
		"subjects":    subjects,
	})
	if err != nil {
		return nil, err
	}

	if _, err = fIn.Write(data); err != nil {
		return nil, err
	}
	if err = fIn.Close(); err != nil {
		return nil, err
	}

	// invoke node
	// #nosec audit: the arguments DocxExportPath, fIn.Name(), fOut.Name() are not user controlled and cannot be injected.
	cmd := exec.Command("node", fmt.Sprintf("%s/dist/subjects.js", p.cfg.DocxExportPath), fIn.Name(), fOut.Name())
	println(cmd.String())
	err = cmd.Run()
	if err != nil {
		return nil, err
	}

	out, err := io.ReadAll(fOut)
	if err != nil {
		return nil, err
	}

	return bytes.NewBuffer(out), nil
}
