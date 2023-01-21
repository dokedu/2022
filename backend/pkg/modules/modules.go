package modules

import (
	"github.com/uptrace/bun"
)

type Modules struct {
	MeiliSearch *MeiliSearchModule
	Printer     *PrinterModule
	Supabase    *SupabaseModule
}

func New(mCfg MeiliSearchConfig, sCfg SupabaseModuleConfig, pCfg PrinterConfig, db *bun.DB) (*Modules, error) {
	var err error
	mods := &Modules{}

	mods.Printer, err = NewPrinterModule(pCfg, mods, db)
	if err != nil {
		return nil, err
	}
	mods.MeiliSearch = NewMeiliSearchModule(mCfg, db)
	mods.Supabase = NewSupabaseModule(sCfg)

	return mods, nil
}
