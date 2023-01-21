import { defineStore } from 'pinia'
import {
  Account,
  Competence,
  EntryAccount,
  EntryAccountCompetence,
  EntryEvent,
  EntryFile,
  EntryTag,
  Tag,
} from '../../../backend/test/types/index'
import { nanoid } from 'nanoid'
import supabase from '../api/supabase'
import { useStore } from './store'
import { getOrganisationId } from '../helper/general'

interface EntryStoreState {
  id: string
  date: string
  body: string | object
  account_id: string
  entry_accounts: EntryAccount[]
  entry_account_competences: EntryAccountCompetence[]
  entry_events: EntryEvent[]
  entry_files: EntryFile[]
  entry_tags: EntryTag[]
  created_at: null | string
  openModal: string
  filters: {
    account_id: null | string
    student_id: null | string
    limit: number | string
    offset: number
    search: string
  }
}

// reduces entry account competences to its unique competences
export const reduceEACsToCompetences = (array: EntryAccountCompetence[]) => {
  if (array.length === 0) return []

  array = array.filter((el) => el.deleted_at === null)

  return [...new Set(array.map((obj) => obj.competence_id))].map((competence_id) => {
    return array.find((obj) => obj.competence_id === competence_id)
  }) as EntryAccountCompetence[]
}

export const useEntryStore = defineStore('entry', {
  state: () => {
    return {
      id: nanoid(),
      date: new Date().toISOString().substr(0, 10), //new Date().toISOString().substr(0, 10)
      body: '',
      account_id: '',
      entry_accounts: [],
      entry_account_competences: [],
      entry_events: [],
      entry_files: [],
      entry_tags: [],
      created_at: null,
      openModal: '',
      filters: {
        account_id: null,
        student_id: null,
        limit: 10,
        offset: 0,
        search: '',
      },
    } as EntryStoreState
  },
  getters: {
    competences: (state) => {
      return reduceEACsToCompetences(state.entry_account_competences.filter((el) => el.deleted_at === null))
    },
    accounts: (state) => {
      return state.entry_accounts.filter((el) => el.deleted_at === null)
    },
    events: (state) => {
      return state.entry_events.filter((el) => el.deleted_at === null)
    },
    files: (state) => {
      return state.entry_files.filter((el) => el.deleted_at === null)
    },
  },
  actions: {
    deleteFile(file: EntryFile) {
      const index = this.entry_files.findIndex((el) => el.id === file.id)
      this.entry_files[index].deleted_at = new Date().toISOString()
    },
    addEvent(event: EntryEvent) {
      // because we are using deleted_at, we need to check if the event is already in the list
      const existing = this.entry_events.find((el) => el.event_id === event.id)
      if (existing) {
        existing.deleted_at = null
      } else {
        this.entry_events.push({ id: nanoid(), entry_id: this.id, event_id: event.id, event, deleted_at: null })
      }
    },
    removeEvent(event: EntryEvent) {
      for (const item of this.entry_events) {
        if (item.id === event.id) {
          item.deleted_at = new Date().toISOString()
          break
        }
      }
    },
    addTag(tag: Tag) {
      // because we are using deleted_at, we need to check if the tag is already in the list
      const existing = this.entry_tags.find((el) => el.tag_id === tag.id)
      if (existing) {
        existing.deleted_at = null
      } else {
        this.entry_tags.push({ id: nanoid(), entry_id: this.id, tag_id: tag.id, tag, deleted_at: null })
      }
    },
    removeTag(tag: EntryTag) {
      for (const entry_tag of this.entry_tags) {
        if (entry_tag.id === tag.id) {
          entry_tag.deleted_at = new Date().toISOString()
          break
        }
      }
    },
    setLevel({ eac, level }) {
      const eacs = this.entry_account_competences.filter((el) => el.competence_id === eac.competence_id)

      for (const item of eacs) {
        item.level = level > 3 ? 0 : level
      }
    },
    getEntryById(id: string) {
      return supabase
        .from('view_entries')
        .select('id, body, created_at, date,account:accounts ( id, first_name, last_name )')
        .eq('id', id)
        .single()
    },
    addCompetence(competence: Competence) {
      // because we are using deleted_at, we need to check if the account is already in the list
      const existing = this.entry_account_competences.filter((el) => el.competence_id === competence.id)

      if (existing.length === this.entry_accounts.length) {
        for (const item of existing) {
          item.deleted_at = null
        }
        return true
      }

      for (const entryAccount of this.entry_accounts) {
        const entryAccountCompetence: EntryAccountCompetence = {
          id: nanoid(),
          level: 1,
          account_id: entryAccount.account_id,
          account: entryAccount.account,
          entry_id: this.id,
          competence_id: competence.id,
          competence,
          deleted_at: null,
        }
        this.entry_account_competences.push(entryAccountCompetence)
      }
    },
    removeCompetence(eac: EntryAccountCompetence) {
      for (const item of this.entry_account_competences) {
        if (item.competence_id === eac.competence_id) {
          item.deleted_at = new Date().toISOString()
        }
      }
    },
    addAccount(account: Account) {
      console.log(account)
      // because we are using deleted_at, we need to check if the account is already in the list
      const existing: EntryAccount | undefined = this.entry_accounts.find((el) => el.account_id === account.id)
      if (existing !== undefined) {
        existing.deleted_at = null
        return true
      }

      this.entry_accounts.push({
        id: nanoid(),
        entry_id: this.id,
        account_id: account.id,
        account,
        deleted_at: null,
      })

      // TODO: only add competences that also all other students already have
      //  been added to, this is to prevent that if a teacher added a
      //  competences just to a single or a selected group of competences to
      //  a student it isn't added to all students
      for (const eac of this.competences) {
        this.entry_account_competences.push({
          id: nanoid(),
          level: eac.level,
          account_id: account.id,
          entry_id: this.id,
          competence_id: eac.competence_id,
          competence: eac.competence,
          deleted_at: null,
        })
      }
    },
    removeAccount(entryAccounts: EntryAccount) {
      const account = this.entry_accounts.find((el) => el.id === entryAccounts.id)
      if (account === undefined) return

      account.deleted_at = new Date().toISOString()

      // remove all entry_account_competences that are linked to this account
      for (const eac of this.entry_account_competences) {
        if (eac.account_id === entryAccounts.account_id) {
          eac.deleted_at = new Date().toISOString()
        }
      }
    },
    async save() {
      const id = this.id

      const success = await this.upsert()
      this.$reset()

      if (success) return { id }

      return false
    },
    async upsert() {
      const accountId = useStore().account.id
      const entryData = { id: this.id, date: this.date, body: this.body, account_id: accountId }

      const entries = await supabase.from('entries').upsert(entryData).match({ id: this.id }).select().single()
      if (entries.error) return false

      const ee = this.entry_events.map((el) => ({
        id: el.id,
        event_id: el.event_id,
        entry_id: this.id,
        deleted_at: el.deleted_at,
      }))
      const events = supabase.from('entry_events').upsert(ee).select()

      const ec = this.entry_accounts.map((el) => ({
        id: el.id,
        account_id: el.account_id,
        entry_id: this.id,
        deleted_at: el.deleted_at,
      }))
      const accounts = supabase.from('entry_accounts').upsert(ec).select()

      const eac = this.entry_account_competences.map((el) => ({
        id: el.id,
        level: el.level,
        account_id: el.account_id,
        entry_id: this.id,
        competence_id: el.competence_id,
        deleted_at: el.deleted_at,
      }))
      const accountCompetences = supabase.from('entry_account_competences').upsert(eac).select()

      const entryFiles = supabase.from('entry_files').upsert(this.entry_files).select()

      const et = this.entry_tags.map((el) => ({
        id: el.id,
        tag_id: el.tag_id,
        entry_id: this.id,
        deleted_at: el.deleted_at,
        organisation_id: getOrganisationId(),
      }))
      const tags = supabase.from('entry_tags').upsert(et).select()
      await Promise.all([events, accounts, accountCompetences, entryFiles, tags])

      // TODO: upsert projects and files

      return true
    },
  },
})
