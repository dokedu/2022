import { SupabaseClient } from '@supabase/supabase-js'
import axios from 'axios'

export default class ApiClient extends SupabaseClient {
  constructor(supabase: SupabaseClient) {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    super(supabase.supabaseUrl, supabase.supabaseKey)
    Object.assign(this, supabase)
  }

  private getHeaders() {
    return {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      apikey: this.supabaseKey,
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      Authorization: `Bearer ${this.auth.currentSession?.access_token}`,
    }
  }

  public async resetIndex(orgId: string): Promise<any> {
    try {
      return {
        error: null,
        data: (
          await axios.post(
            `${this.supabaseUrl}/backend/meili/reset?organisation_id=${orgId}`,
            {},
            {
              headers: this.getHeaders(),
            },
          )
        ).data,
      }
    } catch (e: any) {
      return { error: e.response }
    }
  }

  public async meiliSearch(
    orgId: string,
    q = 't',
    options = {
      limit: 10,
    } as { limit: number; filter?: string },
  ): Promise<any> {
    try {
      return {
        error: null,
        data: (
          await axios.post(
            `${this.supabaseUrl}/backend/meili/indexes/${orgId}/search`,
            {
              q,
              ...options,
            },
            {
              headers: this.getHeaders(),
            },
          )
        ).data,
      }
    } catch (e: any) {
      return { error: e.response }
    }
  }

  public async initAccount() {
    try {
      return {
        error: null,
        data: (
          await axios.post(
            `${this.supabaseUrl}/backend/auth/init_account`,
            {},
            {
              headers: this.getHeaders(),
            },
          )
        ).data,
      }
    } catch (e: any) {
      return { error: e.response }
    }
  }

  public async initIdentity() {
    try {
      return {
        error: null,
        data: (
          await axios.post(
            `${this.supabaseUrl}/backend/auth/init_identity`,
            {},
            {
              headers: this.getHeaders(),
            },
          )
        ).data,
      }
    } catch (e: any) {
      return { error: e.response }
    }
  }

  public async inviteUser(
    orgId: string | null,
    user: { email: string; first_name: string; last_name: string; role: string },
  ): Promise<any> {
    try {
      return {
        error: null,
        data: (
          await axios.post(
            `${this.supabaseUrl}/backend/auth/invite`,
            {
              organisation_id: orgId,
              ...user,
            },
            {
              headers: this.getHeaders(),
            },
          )
        ).data,
      }
    } catch (e: any) {
      return { error: e.response }
    }
  }
}
