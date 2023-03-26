export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json }
  | Json[]

export interface Database {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          operationName?: string
          query?: string
          variables?: Json
          extensions?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      accounts: {
        Row: {
          avatar_file_bucket_id: string | null
          avatar_file_name: string | null
          birthday: string | null
          created_at: string
          deleted_at: string | null
          first_name: string
          grade: number | null
          id: string
          identity_id: string | null
          joined_at: string | null
          last_name: string
          left_at: string | null
          organisation_id: string
          role: string
        }
        Insert: {
          avatar_file_bucket_id?: string | null
          avatar_file_name?: string | null
          birthday?: string | null
          created_at?: string
          deleted_at?: string | null
          first_name: string
          grade?: number | null
          id?: string
          identity_id?: string | null
          joined_at?: string | null
          last_name: string
          left_at?: string | null
          organisation_id: string
          role: string
        }
        Update: {
          avatar_file_bucket_id?: string | null
          avatar_file_name?: string | null
          birthday?: string | null
          created_at?: string
          deleted_at?: string | null
          first_name?: string
          grade?: number | null
          id?: string
          identity_id?: string | null
          joined_at?: string | null
          last_name?: string
          left_at?: string | null
          organisation_id?: string
          role?: string
        }
      }
      addresses: {
        Row: {
          city: string
          country: string
          created_at: string
          deleted_at: string | null
          id: string
          state: string
          street: string
          zip: string
        }
        Insert: {
          city: string
          country: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          state: string
          street: string
          zip: string
        }
        Update: {
          city?: string
          country?: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          state?: string
          street?: string
          zip?: string
        }
      }
      competences: {
        Row: {
          color: string | null
          competence_id: string | null
          competence_type: string
          created_at: string
          curriculum_id: string | null
          deleted_at: string | null
          grades: number[]
          id: string
          name: string
          organisation_id: string
        }
        Insert: {
          color?: string | null
          competence_id?: string | null
          competence_type: string
          created_at?: string
          curriculum_id?: string | null
          deleted_at?: string | null
          grades: number[]
          id?: string
          name: string
          organisation_id: string
        }
        Update: {
          color?: string | null
          competence_id?: string | null
          competence_type?: string
          created_at?: string
          curriculum_id?: string | null
          deleted_at?: string | null
          grades?: number[]
          id?: string
          name?: string
          organisation_id?: string
        }
      }
      entries: {
        Row: {
          account_id: string
          body: Json
          created_at: string
          date: string
          deleted_at: string | null
          id: string
          organisation_id: string
        }
        Insert: {
          account_id: string
          body: Json
          created_at?: string
          date: string
          deleted_at?: string | null
          id?: string
          organisation_id: string
        }
        Update: {
          account_id?: string
          body?: Json
          created_at?: string
          date?: string
          deleted_at?: string | null
          id?: string
          organisation_id?: string
        }
      }
      entry_account_competences: {
        Row: {
          account_id: string
          competence_id: string
          created_at: string
          deleted_at: string | null
          entry_id: string
          id: string
          level: number
          organisation_id: string
        }
        Insert: {
          account_id: string
          competence_id: string
          created_at?: string
          deleted_at?: string | null
          entry_id: string
          id?: string
          level: number
          organisation_id: string
        }
        Update: {
          account_id?: string
          competence_id?: string
          created_at?: string
          deleted_at?: string | null
          entry_id?: string
          id?: string
          level?: number
          organisation_id?: string
        }
      }
      entry_accounts: {
        Row: {
          account_id: string
          created_at: string
          deleted_at: string | null
          entry_id: string
          id: string
          organisation_id: string
        }
        Insert: {
          account_id: string
          created_at?: string
          deleted_at?: string | null
          entry_id: string
          id?: string
          organisation_id: string
        }
        Update: {
          account_id?: string
          created_at?: string
          deleted_at?: string | null
          entry_id?: string
          id?: string
          organisation_id?: string
        }
      }
      entry_events: {
        Row: {
          created_at: string
          deleted_at: string | null
          entry_id: string
          event_id: string
          id: string
          organisation_id: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          entry_id: string
          event_id: string
          id?: string
          organisation_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          entry_id?: string
          event_id?: string
          id?: string
          organisation_id?: string
        }
      }
      entry_files: {
        Row: {
          created_at: string
          deleted_at: string | null
          entry_id: string
          file_bucket_id: string
          file_name: string
          id: string
          organisation_id: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          entry_id: string
          file_bucket_id: string
          file_name: string
          id?: string
          organisation_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          entry_id?: string
          file_bucket_id?: string
          file_name?: string
          id?: string
          organisation_id?: string
        }
      }
      entry_tags: {
        Row: {
          created_at: string
          deleted_at: string | null
          entry_id: string
          id: string
          organisation_id: string
          tag_id: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          entry_id: string
          id?: string
          organisation_id: string
          tag_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          entry_id?: string
          id?: string
          organisation_id?: string
          tag_id?: string
        }
      }
      event_competences: {
        Row: {
          competence_id: string
          created_at: string
          deleted_at: string | null
          event_id: string
          id: string
          organisation_id: string
        }
        Insert: {
          competence_id: string
          created_at?: string
          deleted_at?: string | null
          event_id: string
          id?: string
          organisation_id: string
        }
        Update: {
          competence_id?: string
          created_at?: string
          deleted_at?: string | null
          event_id?: string
          id?: string
          organisation_id?: string
        }
      }
      events: {
        Row: {
          body: string
          created_at: string
          deleted_at: string | null
          ends_at: string
          id: string
          image_file_bucket_id: string | null
          image_file_name: string | null
          organisation_id: string
          recurrence: string[] | null
          starts_at: string
          title: string
        }
        Insert: {
          body: string
          created_at?: string
          deleted_at?: string | null
          ends_at: string
          id?: string
          image_file_bucket_id?: string | null
          image_file_name?: string | null
          organisation_id: string
          recurrence?: string[] | null
          starts_at: string
          title: string
        }
        Update: {
          body?: string
          created_at?: string
          deleted_at?: string | null
          ends_at?: string
          id?: string
          image_file_bucket_id?: string | null
          image_file_name?: string | null
          organisation_id?: string
          recurrence?: string[] | null
          starts_at?: string
          title?: string
        }
      }
      identities: {
        Row: {
          created_at: string
          deleted_at: string | null
          global_role: string
          id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          global_role: string
          id?: string
          user_id: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          global_role?: string
          id?: string
          user_id?: string
        }
      }
      organisations: {
        Row: {
          address_id: string
          created_at: string
          deleted_at: string | null
          id: string
          legal_name: string
          name: string
          owner_id: string
          phone: string
          website: string
        }
        Insert: {
          address_id: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          legal_name: string
          name: string
          owner_id: string
          phone: string
          website: string
        }
        Update: {
          address_id?: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          legal_name?: string
          name?: string
          owner_id?: string
          phone?: string
          website?: string
        }
      }
      reports: {
        Row: {
          account_id: string
          created_at: string
          deleted_at: string | null
          file_bucket_id: string | null
          file_name: string | null
          filter_tags: string[] | null
          from: string
          id: string
          meta: Json | null
          organisation_id: string
          status: string
          student_account_id: string
          to: string
          type: string
        }
        Insert: {
          account_id: string
          created_at?: string
          deleted_at?: string | null
          file_bucket_id?: string | null
          file_name?: string | null
          filter_tags?: string[] | null
          from: string
          id?: string
          meta?: Json | null
          organisation_id: string
          status?: string
          student_account_id: string
          to: string
          type: string
        }
        Update: {
          account_id?: string
          created_at?: string
          deleted_at?: string | null
          file_bucket_id?: string | null
          file_name?: string | null
          filter_tags?: string[] | null
          from?: string
          id?: string
          meta?: Json | null
          organisation_id?: string
          status?: string
          student_account_id?: string
          to?: string
          type?: string
        }
      }
      tags: {
        Row: {
          created_at: string
          created_by: string
          deleted_at: string | null
          id: string
          name: string
          organisation_id: string
        }
        Insert: {
          created_at?: string
          created_by: string
          deleted_at?: string | null
          id?: string
          name: string
          organisation_id: string
        }
        Update: {
          created_at?: string
          created_by?: string
          deleted_at?: string | null
          id?: string
          name?: string
          organisation_id?: string
        }
      }
    }
    Views: {
      view_entries: {
        Row: {
          account_id: string | null
          body: Json | null
          created_at: string | null
          date: string | null
          deleted_at: string | null
          id: string | null
        }
      }
    }
    Functions: {
      export_events: {
        Args: {
          _organisation_id: string
          _from: string
          _to: string
          _show_archived: boolean
        }
        Returns: {
          id: string
          title: string
          body: string
          starts_at: string
          ends_at: string
          subjects: Json
        }[]
      }
      get_competence_tree: {
        Args: {
          _competence_id: string
        }
        Returns: {
          id: string
          name: string
          competence_type: string
          grades: number[]
          competence_id: string
          created_at: string
        }[]
      }
      identity_account_ids: {
        Args: Record<PropertyKey, never>
        Returns: string[]
      }
      identity_account_ids_role: {
        Args: {
          _roles: string[]
        }
        Returns: string[]
      }
      identity_id: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      identity_organisation_ids: {
        Args: Record<PropertyKey, never>
        Returns: string[]
      }
      identity_organisation_ids_role: {
        Args: {
          _roles: string[]
        }
        Returns: string[]
      }
      is_allowed_to_crud_entry: {
        Args: {
          _entry_account_id: string
        }
        Returns: boolean
      }
      nanoid: {
        Args: {
          size?: number
        }
        Returns: string
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  storage: {
    Tables: {
      buckets: {
        Row: {
          allowed_mime_types: string[] | null
          avif_autodetection: boolean | null
          created_at: string | null
          file_size_limit: number | null
          id: string
          name: string
          owner: string | null
          public: boolean | null
          updated_at: string | null
        }
        Insert: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id: string
          name: string
          owner?: string | null
          public?: boolean | null
          updated_at?: string | null
        }
        Update: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id?: string
          name?: string
          owner?: string | null
          public?: boolean | null
          updated_at?: string | null
        }
      }
      migrations: {
        Row: {
          executed_at: string | null
          hash: string
          id: number
          name: string
        }
        Insert: {
          executed_at?: string | null
          hash: string
          id: number
          name: string
        }
        Update: {
          executed_at?: string | null
          hash?: string
          id?: number
          name?: string
        }
      }
      objects: {
        Row: {
          bucket_id: string | null
          created_at: string | null
          id: string
          last_accessed_at: string | null
          metadata: Json | null
          name: string | null
          owner: string | null
          path_tokens: string[] | null
          updated_at: string | null
        }
        Insert: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
        }
        Update: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      extension: {
        Args: {
          name: string
        }
        Returns: string
      }
      filename: {
        Args: {
          name: string
        }
        Returns: string
      }
      foldername: {
        Args: {
          name: string
        }
        Returns: string[]
      }
      get_size_by_bucket: {
        Args: Record<PropertyKey, never>
        Returns: {
          size: number
          bucket_id: string
        }[]
      }
      search: {
        Args: {
          prefix: string
          bucketname: string
          limits?: number
          levels?: number
          offsets?: number
          search?: string
          sortcolumn?: string
          sortorder?: string
        }
        Returns: {
          name: string
          id: string
          updated_at: string
          created_at: string
          last_accessed_at: string
          metadata: Json
        }[]
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

