import { defineStore } from 'pinia'
import supabase from '../api/supabase'
import { useStore } from './store'

import { Database } from '../types/schema.types'
type Account = Database['public']['Tables']['accounts']['Row']
type Report = Database['public']['Tables']['reports']['Row']
type Tag = Database['public']['Tables']['tags']['Row']

type ReportStoreState = { [K in keyof Report]: Report[K] | undefined } & {
  author_account: Account | undefined
  student_account: Account | undefined
  filter_tags: Tag[] | undefined
}

export const useReportStore = defineStore('report', {
  state: () => {
    return {
      meta: undefined,
      id: undefined,
      account_id: undefined,
      student_account_id: undefined,
      student_account: undefined,
      from: undefined,
      to: undefined,
      status: undefined,
      type: 'report',
      filter_tags: undefined,
    } as ReportStoreState
  },
  actions: {
    async loadReport(id: string) {
      const { data, error } = await supabase
        .from('reports')
        .select(
          '*, author_account:account_id(id, first_name, last_name), student_account:student_account_id(id, first_name, last_name)',
        )
        .eq('id', id)
        .single()

      if (error) {
        console.error(error)
        return
      }

      Object.assign(this, data)
    },
    async create() {
      let tags: string[] | undefined = undefined
      if (this.type === 'report' && this.filter_tags && this.filter_tags.length > 0) {
        tags = this.filter_tags.map((tag: Tag) => tag.id)
      }

      await supabase
        .from<Report>('reports')
        .insert({
          account_id: useStore().account.id,
          student_account_id: this.student_account_id,
          from: this.from,
          to: this.to,
          type: this.type,
          status: 'pending',
          filter_tags: tags,
        })
        .select()
        .single()

      return true
    },
    async createSignedUrl() {
      if (!this.file_bucket_id || !this.file_name) return null
      const res = await supabase.storage.from(this.file_bucket_id).createSignedUrl(this.file_name, 60)

      if (res.error) {
        console.error(res.error)
        throw res.error
      }

      return res.data.signedUrl
    },
  },
})
