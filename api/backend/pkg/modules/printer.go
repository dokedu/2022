package modules

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/dokedu/dokedu-api-beta/services/internal/print_templates"
	"github.com/dokedu/dokedu-api-beta/services/pkg/models"
	"github.com/go-rod/rod"
	"github.com/go-rod/rod/lib/launcher"
	"github.com/go-rod/rod/lib/proto"
	gonanoid "github.com/matoous/go-nanoid/v2"
	log "github.com/sirupsen/logrus"
	"github.com/uptrace/bun"
	"github.com/uptrace/bun/dialect/pgdialect"
	"github.com/uptrace/bun/driver/pgdriver"
	"golang.org/x/sync/semaphore"
	"os"
	"path"
	"sort"
	"time"
)

type PrinterModule struct {
	Templates    print_templates.PrintTemplate
	DB           *bun.DB
	mods         *Modules
	cfg          PrinterConfig
	printingLock *semaphore.Weighted
	launcher     *launcher.Launcher
}

type PrinterConfig struct {
	Folder string
	RodURL string

	DocxExportPath string
}

func NewPrinterModule(cfg PrinterConfig, mods *Modules, db *bun.DB) (*PrinterModule, error) {
	ctx := context.Background()
	pt, err := print_templates.New()
	if err != nil {
		return nil, err
	}

	pm := &PrinterModule{
		cfg:       cfg,
		mods:      mods,
		Templates: pt,
		DB:        db,
		// allow up to 3 browsers at the same time
		printingLock: semaphore.NewWeighted(3),
		launcher:     launcher.MustNewManaged(cfg.RodURL).NoSandbox(true),
	}

	listener := pgdriver.NewListener(db)
	err = listener.Listen(context.Background(), "app.report_created")
	if err != nil {
		return nil, err
	}

	go func() {
		notificationChan := listener.Channel()
		for {
			notification := <-notificationChan

			if notification.Channel != "app.report_created" {
				continue
			}

			id := notification.Payload
			log.Infof("got notification for report %s", id)
			// load report
			var report models.Report
			err := db.NewSelect().Model(&report).Relation("Account").Where("report.id = ?", id).Scan(ctx)
			if err != nil {
				log.Error(err)
				continue
			}

			go func() {
				err := pm.HandleNewReport(report)
				if err != nil {
					log.Error(err)

					meta := map[string]interface{}{
						"error": err.Error(),
					}
					metaC, err := json.Marshal(meta)
					if err != nil {
						log.Errorf("error during report generation: %+v", err)
					}

					report.Status = models.ReportStatusError
					report.Meta = sql.NullString{String: string(metaC), Valid: true}

					_, err = db.NewUpdate().
						Model(&report).
						Where("id = ?", report.ID).Exec(ctx)
					if err != nil {
						log.Error(err)
					}
				}
			}()

		}
	}()
	return pm, nil
}

func (p *PrinterModule) HandleNewReport(report models.Report) error {
	// make sure status is pending
	if report.Status != models.ReportStatusPending {
		return errors.New("report status is not pending")
	}

	var err error
	var buf *bytes.Buffer
	switch report.Type {
	case models.ReportTypeReport:
		buf, err = p.HandleNewReportTypeReport(report)
	case models.ReportTypeSubjects:
		buf, err = p.HandleNewReportTypeSubjects(report)
	case models.ReportTypeDocx:
		buf, err = p.HandleNewReportTypeDocxReport(report)
	case models.ReportTypeDocxSubjects:
		buf, err = p.HandleNewReportTypeDocxSubject(report)
	default:
		return errors.New("report type is not supported")
	}
	if err != nil {
		return err
	}

	// upload document
	err = p.mods.Supabase.UploadFile(report.Account.OrganisationID, fmt.Sprintf("reports/%s.%s", report.ID, report.GetFileEnding()), buf, report.GetMimeType())
	if err != nil {
		return err
	}

	// update report status
	report.Status = models.ReportStatusDone
	report.FileBucketID = sql.NullString{
		String: "org_" + report.Account.OrganisationID,
		Valid:  true,
	}
	report.FileName = sql.NullString{
		String: fmt.Sprintf("reports/%s.%s", report.ID, report.GetFileEnding()),
		Valid:  true,
	}

	_, err = p.DB.NewUpdate().Model(&report).Where("id = ?", report.ID).Exec(context.Background())
	if err != nil {
		return err
	}

	return nil
}

type FetchEntriesForReportTypeReportResponse struct {
	ID               string
	AccountID        string
	Date             time.Time
	Body             string
	TeacherFirstName string
	TeacherLastName  string
	Tags             []string `bun:",array"`
}

func (p *PrinterModule) FetchEntriesForReportTypeReport(ctx context.Context, report models.Report) ([]FetchEntriesForReportTypeReportResponse, error) {
	// fetch data
	var entries []FetchEntriesForReportTypeReportResponse

	query := p.DB.NewSelect().
		ColumnExpr("e.id, ea.account_id, e.date, e.body, a.first_name as teacher_first_name, a.last_name as teacher_last_name, array_agg(t.name) as tags").
		TableExpr("entries e").
		Join("inner join accounts a on a.id = e.account_id").
		Join("inner join entry_accounts ea on e.id = ea.entry_id").
		Where("ea.account_id = ?", report.StudentAccountID).
		Where("e.date::date >= ?::date and e.date::date <= ?::date", report.From, report.To).
		Where("e.deleted_at is null and ea.deleted_at is null").
		Order("e.date desc").
		Group("e.id", "ea.account_id", "e.date", "e.body", "a.first_name", "a.last_name").
		Join("left join entry_tags et on e.id = et.entry_id").
		Join("left join tags t on t.id = et.tag_id")

	if len(report.FilterTags) > 0 {
		query = query.
			Having("array_agg(t.id) @> (?)", pgdialect.Array(report.FilterTags))
	}

	err := query.Scan(ctx, &entries)
	if err != nil {
		return nil, err
	}

	// unfortunately, we need to clean up "empty" tag arrays
	for i, entry := range entries {
		if len(entry.Tags) == 1 && entry.Tags[0] == "" {
			entries[i].Tags = nil
		}
	}

	return entries, nil
}

func (p *PrinterModule) HandleNewReportTypeReport(report models.Report) (*bytes.Buffer, error) {
	ctx := context.Background()

	var student models.Account
	err := p.DB.NewSelect().Model(&student).Where("id = ?", report.StudentAccountID).Scan(ctx)
	if err != nil {
		return nil, err
	}

	entries, err := p.FetchEntriesForReportTypeReport(ctx, report)
	if err != nil {
		return nil, err
	}

	entryIDs := make([]string, len(entries))
	for i, entry := range entries {
		entryIDs[i] = entry.ID
	}

	if len(entryIDs) == 0 {
		return nil, fmt.Errorf("no entries found for user %s in time range %s - %s", report.StudentAccountID, report.From, report.To)
	}

	// load directly attached competences
	var competences []map[string]interface{}
	err = p.DB.NewSelect().
		TableExpr("competences c").
		ColumnExpr("eac.entry_id, c.id, c.name, eac.level").
		Join("inner join entry_account_competences eac on eac.competence_id = c.id").
		Where("eac.entry_id in (?) and eac.account_id = ?", bun.In(entryIDs), student.ID).
		Where("eac.deleted_at is null").
		Scan(ctx, &competences)
	if err != nil {
		return nil, err
	}

	// load indirectly attached competences (via projects)
	var projectCompetences []map[string]interface{}
	err = p.DB.NewSelect().
		TableExpr("entry_events ev").
		ColumnExpr("ev.entry_id, c.id, c.name").
		Join("inner join event_competences ec on ec.event_id = ev.event_id").
		Join("inner join competences c on ec.competence_id = c.id").
		Where("ev.entry_id in (?)", bun.In(entryIDs)).
		Where("ev.deleted_at is null and ec.deleted_at is null").
		Scan(ctx, &projectCompetences)
	if err != nil {
		return nil, err
	}

	// pivot competences into map with entry id as key
	competencesMap := make(map[string][]print_templates.DataCompetence)
	for _, competence := range competences {
		entryID := competence["entry_id"].(string)
		competencesMap[entryID] = append(competencesMap[entryID], print_templates.DataCompetence{
			Name:  competence["name"].(string),
			Level: int(competence["level"].(int64)),
		})
	}

outer:
	for _, competence := range projectCompetences {
		// check if the competence is present in the other one.
		for _, other := range competences {
			if competence["entry_id"].(string) != other["entry_id"].(string) {
				continue
			}

			if competence["id"].(string) == other["id"].(string) {
				continue outer
			}
		}

		entryID := competence["entry_id"].(string)
		competencesMap[entryID] = append(competencesMap[entryID], print_templates.DataCompetence{
			Name:  competence["name"].(string),
			Level: -1,
		})
	}

	reportDataEntries := make([]print_templates.ReportDataEntry, len(entries))
	for i, entry := range entries {
		reportDataEntries[i] = print_templates.ReportDataEntry{
			ID:          entry.ID,
			Date:        entry.Date,
			Body:        entry.Body,
			Competences: competencesMap[entry.ID],
			Account: models.Account{
				FirstName: entry.TeacherFirstName,
				LastName:  entry.TeacherLastName,
			},
			Tags: entry.Tags,
		}
	}

	return p.PrintReport(print_templates.ReportData{
		HeaderData: print_templates.HeaderData{
			PageType: "Einträge",
			Date: print_templates.HeaderDataDate{
				Today: time.Now(),
				From:  report.From,
				To:    report.To,
			},
			Student: student,
		},
		ContentData: print_templates.ReportContentData{
			Entries: reportDataEntries,
		},
	})
}

func (p *PrinterModule) FetchDataForReportSubjects(report models.Report) (student models.Account, data []print_templates.SubjectContentDataSubject, err error) {
	ctx := context.Background()

	tx, err := p.DB.BeginTx(ctx, nil)
	if err != nil {
		return
	}

	defer func() {
		if err != nil {
			err = tx.Rollback()
		}
	}()

	_, err = tx.Exec("set local request.jwt.claim.role='service_role'")
	if err != nil {
		return
	}

	err = tx.NewSelect().Model(&student).Where("id = ?", report.StudentAccountID).Scan(ctx)
	if err != nil {
		return
	}

	// fetch competences
	res, err := tx.Query(`
	SELECT competence_name, level, competence_id, tree_id, tree_name FROM (
		select
        c.name as competence_name, eac.level, c.id as competence_id, tree.id as tree_id, tree.name as tree_name, row_number() over (partition by c.id order by e.date desc, e.created_at desc) as rn
		FROM entry_account_competences eac
				 inner join entries e on e.id = eac.entry_id
				 inner join competences c on eac.competence_id = c.id,
			 lateral get_competence_tree(eac.competence_id) tree
		WHERE (eac.account_id = ?)
		  AND (e.date::date >= ?::date and e.date::date <= ?::date) 
          and tree.competence_id is null
          and e.deleted_at is null
          and eac.deleted_at is null
	) t
	where t.rn = 1 order by t.tree_name, t.competence_name;
`, report.StudentAccountID, report.From, report.To)
	if err != nil {
		return
	}

	subjects := make(map[string]*print_templates.SubjectContentDataSubject)
	for res.Next() {
		var name, id, subjectID, subjectName string
		var level int

		err = res.Scan(&name, &level, &id, &subjectID, &subjectName)
		if err != nil {
			return
		}

		var subject *print_templates.SubjectContentDataSubject
		var ok bool
		if subject, ok = subjects[subjectID]; !ok {
			subject = &print_templates.SubjectContentDataSubject{
				Name: subjectName,
			}
			subjects[subjectID] = subject
		}

		subject.Competences = append(subject.Competences, print_templates.DataCompetence{
			Name:  name,
			Level: level,
		})
	}
	err = res.Close()
	if err != nil {
		return
	}

	resEvents, err := tx.Query(`
	SELECT competence_name, level, competence_id, tree_id, tree_name FROM (
		select
        c.name as competence_name, -1 as level, c.id as competence_id, tree.id as tree_id, tree.name as tree_name, row_number() over (partition by c.id order by e.date desc, e.created_at desc) as rn
		FROM entry_accounts ea
				 inner join entries e on e.id = ea.entry_id
		    	 inner join entry_events ee on ee.entry_id = ea.entry_id
		    	 inner join event_competences ec on ee.event_id = ec.event_id
				 inner join competences c on ec.competence_id = c.id,
			 lateral get_competence_tree(ec.competence_id) tree
		WHERE (ea.account_id = ?)
		  AND (e.date::date >= ?::date and e.date::date <= ?::date) 
          and tree.competence_id is null
          and e.deleted_at is null
          and ea.deleted_at is null
		  and ec.deleted_at is null
		  and ee.deleted_at is null
	) t
	where t.rn = 1 order by t.tree_name, t.competence_name;
`, report.StudentAccountID, report.From, report.To)
	if err != nil {
		return
	}

outer:
	for resEvents.Next() {
		var name, id, subjectID, subjectName string
		var level int

		err = resEvents.Scan(&name, &level, &id, &subjectID, &subjectName)
		if err != nil {
			return
		}

		var subject *print_templates.SubjectContentDataSubject
		var ok bool
		if subject, ok = subjects[subjectID]; !ok {
			subject = &print_templates.SubjectContentDataSubject{
				Name: subjectName,
			}
			subjects[subjectID] = subject
		}

		for _, competence := range subject.Competences {
			if competence.Name == name {
				continue outer
			}
		}

		subject.Competences = append(subject.Competences, print_templates.DataCompetence{
			Name:  name,
			Level: level,
		})
	}
	err = resEvents.Close()
	if err != nil {
		return
	}

	out := make([]print_templates.SubjectContentDataSubject, len(subjects))
	i := 0
	for _, subject := range subjects {
		out[i] = *subject
		i++
	}
	sort.Slice(out, func(i int, j int) bool { return out[i].Name < out[j].Name })
	err = tx.Commit()
	if err != nil {
		return
	}

	return student, out, nil
}

func (p *PrinterModule) HandleNewReportTypeSubjects(report models.Report) (*bytes.Buffer, error) {
	student, subjects, err := p.FetchDataForReportSubjects(report)
	if err != nil {
		return nil, err
	}

	return p.PrintSubjects(print_templates.SubjectsData{
		HeaderData: print_templates.HeaderData{
			PageType: "Fächer",
			Date: print_templates.HeaderDataDate{
				Today: time.Now(),
				From:  report.From,
				To:    report.To,
			},
			Student: student,
		},
		ContentData: print_templates.SubjectContentData{
			Subjects: subjects,
		},
	})
}

// Printing functions

func (p *PrinterModule) PrintReport(data print_templates.ReportData) (*bytes.Buffer, error) {
	// render report
	header, err := p.Templates.RenderHeader(data.HeaderData)
	if err != nil {
		return nil, err
	}

	footer, err := p.Templates.RenderFooter(data.HeaderData)
	if err != nil {
		return nil, err
	}

	content, err := p.Templates.RenderReport(data.ContentData)
	if err != nil {
		return nil, err
	}

	return p.Print(header, footer, content)
}
func (p *PrinterModule) PrintSubjects(data print_templates.SubjectsData) (*bytes.Buffer, error) {
	// render report
	header, err := p.Templates.RenderHeader(data.HeaderData)
	if err != nil {
		return nil, err
	}

	footer, err := p.Templates.RenderFooter(data.HeaderData)
	if err != nil {
		return nil, err
	}

	content, err := p.Templates.RenderSubjects(data.ContentData)
	if err != nil {
		return nil, err
	}

	return p.Print(header, footer, content)
}
func (p *PrinterModule) Print(header []byte, footer []byte, content []byte) (printRes *bytes.Buffer, err error) {
	ctx := context.Background()

	// try to acquire lock. blocks until lock is acquire
	err = p.printingLock.Acquire(ctx, 1)
	if err != nil {
		return nil, err
	}

	// create a context with a timeout of 5 minutes. the mutex is locked now, and for the next five minutes, this printer session
	// is only in use by us. After the 5 minutes, or if the printing is done (whatever happens first), the lock is released.
	ctx, cancel := context.WithTimeout(ctx, 5*time.Minute)

	defer func() {
		// properly clean up the context and release resource lock.
		cancel()
		p.printingLock.Release(1)

		// also, since we are using rod, which tend to panic sometimes, we need to recover from that.
		if p := recover(); p != nil {
			err = fmt.Errorf("panic in print: %v", p)
			log.Error(err)
		}
	}()

	//create tmp file
	file, err := os.OpenFile(fmt.Sprintf("%s/print_%s.html", p.cfg.Folder, gonanoid.Must()), os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0664)
	if err != nil {
		return nil, err
	}
	fileName := path.Base(file.Name())

	//goland:noinspection GoUnhandledErrorResult
	defer os.Remove(file.Name())
	//goland:noinspection GoUnhandledErrorResult
	defer file.Close()

	// write content to file
	_, err = file.Write(content)
	if err != nil {
		return nil, err
	}

	// launch the browser and get a page
	browser := rod.New().Client(p.launcher.MustClient()).Context(ctx).MustConnect()
	defer browser.MustClose()
	page := browser.MustPage(fmt.Sprintf("file:///data/%s", fileName))

	err = page.WaitIdle(2 * time.Minute)
	if err != nil {
		return nil, err
	}

	err = page.WaitElementsMoreThan("#done", 0)
	if err != nil {
		return nil, err
	}

	reader, err := page.PDF(&proto.PagePrintToPDF{
		Landscape:           false,
		DisplayHeaderFooter: true,
		PrintBackground:     true,
		PaperWidth:          CmToInch(21),
		PaperHeight:         CmToInch(29.7),
		MarginTop:           CmToInch(4.5),
		MarginBottom:        CmToInch(1.5),
		MarginLeft:          CmToInch(1.5),
		MarginRight:         CmToInch(1.5),
		HeaderTemplate:      string(header),
		FooterTemplate:      string(footer),
	})
	if err != nil {
		return nil, err
	}

	// yes, it would be great if we could pass the reader along. But since we want to close the browser as fast as possible,
	// we need to read the reader inside the function.
	buf := &bytes.Buffer{}
	_, err = buf.ReadFrom(reader)
	if err != nil {
		return nil, err
	}

	return buf, nil
}

func CmToInch(cm float64) *float64 {
	value := cm / 2.54
	return &value
}
