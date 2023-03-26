import { defineStore } from 'pinia'
import supabase from '../api/supabase'
import { router } from '../router/_index'

import { Database } from '../types/schema.types'
type Organisation = Database['public']['Tables']['organisations']['Row']

interface StoreState {
  user: {
    id: string
    firstName: string
    lastName: string
    email: string
    password: string
    profilePicture: string
  }
  account: {
    id: string
    role: string
  }
  organisationId: null | string
  organisations: Organisation[]
}

export const useStore = defineStore('main', {
  state: () => {
    return {
      user: {
        id: '',
        firstName: '',
        lastName: '',
        email: '',
        password: '',
        profilePicture: '',
      },
      account: {
        id: '',
        role: '',
      },
      organisationId: null,
      organisations: [],
      entry: {
        id: '',
        date: '',
        description: '',
        account_id: '',
        entry_accounts: [],
        entry_accounts_competences: [],
      },
    } as StoreState
  },
  actions: {
    async getEntries() {
      const { data: entries, error } = await supabase.from('view_entries').select('*')

      if (error) return []
      return entries
    },
    async insertEntry({ body = '', date = '2021-12-11' }) {
      const { data, error } = await supabase
        .from('entries')
        .insert({ body, date, account_id: this.account.id }).select()
        .single()

      if (error) return false
      return data
    },
    async afterLogin(payload?: { user?: { id: string; email?: string } | null } | null) {
      if (!payload?.user) return false
      if (!payload?.user.email) return false

      this.user.id = payload.user.id
      this.user.email = payload.user.email

      // TODO: get account from le database
      const { data: organisations, error } = await supabase.from('organisations').select('*')

      if (error || organisations === null) return false

      this.organisations = organisations

      switch (organisations.length) {
        case 0:
          alert('You must be in an organization to use Dokedu')
          break
        case 1:
          this.organisationId = organisations[0].id
          localStorage.setItem('organisationId', this.organisationId)

          const { data: account, error } = await supabase
            .from('accounts')
            .select('*,identities!inner (user_id)')
            .eq('organisation_id', this.organisationId)
            .eq('identities.user_id', this.user.id)
            .order('created_at')
            .single()

          if (error || account === null) {
            alert('Something went wrong while logging in. Please try again later.')
            await router.push({ name: 'login' })
            break
          }

          this.account = account

          await router.push({ name: 'entries' })
          break
        default:
          // We can skip the workspace selection if the user already has an organization ID in local storage
          if (this.organisationId) {
            await router.push({ name: 'entries' })
          } else {
            await router.push('/login/workspaces')
          }
          break
      }
    },
  },
  persist: true,
})
