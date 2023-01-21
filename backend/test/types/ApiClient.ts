import { SupabaseClient } from "@supabase/supabase-js";
import axios from "axios";

export default class ApiClient extends SupabaseClient {
  constructor(supabase: SupabaseClient) {
    super("http://", "a");
    Object.assign(this, supabase);
  }

  private getHeaders() {
    return {
      "Content-Type": "application/json",
      Accept: "application/json",
      apikey: this.supabaseKey,
      // @ts-ignore
      Authorization: `Bearer ${this.auth.currentSession?.access_token}`,
    };
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
            }
          )
        ).data,
      };
    } catch (e) {
      return { error: e.response };
    }
  }

  public async meiliSearch(
    orgId: string,
    q = "t",
    options = {
      limit: 10,
    } as { limit: number; filter?: string }
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
            }
          )
        ).data,
      };
    } catch (e) {
      return { error: e.response };
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
            }
          )
        ).data,
      };
    } catch (e) {
      return { error: e.response };
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
            }
          )
        ).data,
      };
    } catch (e) {
      return { error: e.response };
    }
  }
}
