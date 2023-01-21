import { defineStore } from 'pinia'
import { Competence } from '../../../backend/test/types/index'
import supabase from '../api/supabase'

interface EntryStoreState {
  search: string
  subjects: Competence[]
  groups: Competence[]
  competences: Competence[]
  selected: Competence[]
  filters: Competence[]
  limit: {
    subject: number
    group: number
    competence: number
  }
  refetch: boolean
}

type CompetenceType = 'subject' | 'group' | 'competence'

export const useCompetenceSearchStore = defineStore('competence-search', {
  state: () => {
    return {
      search: '',
      subjects: [],
      groups: [],
      competences: [],
      selected: [],
      filters: [],
      limit: {
        subject: 3,
        group: 3,
        competence: 3,
      },
      refetch: false,
    } as EntryStoreState
  },
  actions: {
    getCompetences(type: CompetenceType, limit = 3, ids: string[] = []) {
      let fetcher = supabase.from('competences')

      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      fetcher = fetcher
        .select('id, name, grades, competence_id', { count: 'exact' })
        .eq('competence_type', type)
        .ilike('name', `%${this.search}%`)
        .order('name', { ascending: true })
        .limit(limit)

      if (this.filters.length > 0) {
        // const orFilter = this.filters.map((el) => `competence_id.eq.${el.id}`).join(',')
        const orFilter = `competence_id.eq.${this.filters[this.filters.length - 1].id}`
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        fetcher = fetcher.or(orFilter)
      }

      return fetcher
    },
    addFilter(competence: Competence) {
      // if competence is not already in filters add it
      if (!this.filters.find((el) => el.id === competence.id)) {
        this.filters.push(competence)
        this.refetch = true
      }
    },
    removeFilter(competence: Competence) {
      this.filters = this.filters.filter((el) => el.id !== competence.id)
      this.refetch = true
    },
    addCompetence(competence: Competence) {
      // if competence is not already in selected add it
      if (!this.selected.find((el) => el.id === competence.id)) {
        this.selected.push(competence)
      }
    },
  },
})
