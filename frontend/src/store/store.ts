import { defineStore } from 'pinia'
import supabase from '../api/supabase'
import { Account, Organisation } from '../../../backend/test/types'
import { router } from '../router/_index'

interface StoreState {
  user: {
    id: string
    firstName: string
    lastName: string
    email: string
    password: string
    profilePicture: string
    isLoggedIn: boolean
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
        isLoggedIn: false,
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
      const { data: organisations, error } = await supabase.from<Organisation>('organisations').select('*')

      if (error || organisations === null) return false

      // TODO: inform user he needs to be in a organisation to use Dokedu
      if (organisations.length === 0) return false

      this.organisations = organisations

      if (organisations.length === 1) {
        this.organisationId = organisations[0].id
        localStorage.setItem('organisationId', this.organisationId)

        const { data: account, error } = await supabase
          .from<Account & { 'identities.user_id': string }>('accounts')
          .select('*,identities!inner (user_id)')
          .eq('organisation_id', this.organisationId)
          .eq('identities.user_id', this.user.id)
          .order('created_at')
          .single()

        if (error || account === null) return false

        this.account = account
      }

      this.user.isLoggedIn = true

      if (organisations.length > 1) {
        // if the org_id is not set, forward to account switcher
        if (!this.organisationId) {
          await router.push('/login/workspaces')
        }
      }
    },
  },
  persist: true,
})
