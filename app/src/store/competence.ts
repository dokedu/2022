import { defineStore } from 'pinia'
import supabase from '../api/supabase'
import { Database } from '../types/schema.types'

type Competence = Database['public']['Tables']['competences']['Row']

type CompetenceStoreState = {
  competences: Competence[]
}

export const useCompetenceStore = defineStore('competence', {
  state: () => {
    return {
      competences: [],
    } as CompetenceStoreState
  },
  actions: {
    async toggleCompetence(competence: Competence) {
      if (this.competences.find((el) => el.id === competence.id)) {
        // remove competence
        this.competences = this.competences.filter((el) => el.id !== competence.id)
      } else {
        const { data: parents } = await supabase
          .rpc('get_competence_tree', { _competence_id: competence.id })
          .select()

        this.competences.push(Object.assign({}, competence, { parents }))
      }
    },
  },
  persist: true,
})
