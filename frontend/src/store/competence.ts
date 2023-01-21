import { defineStore } from 'pinia'
import { Competence } from '../../../backend/test/types/index'
import supabase from '../api/supabase'

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
          .rpc<Competence>('get_competence_tree', { _competence_id: competence.id })
          .select()

        this.competences.push(Object.assign({}, competence, { parents }))
      }
    },
  },
})
