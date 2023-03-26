export interface Organisation {
  id: string;
  name: string;
  address_id: string;
  legal_name: string;
  website: string;
  phone: string;
  owner_id: string;
  created_at: string;
}

export interface Identity {
  id: string;
  global_role: string;
  created_at: string;
  user_id: string;
}

export interface Account {
  id: string;
  role: string;
  identity_id?: string;
  organisation_id: string;
  first_name: string;
  last_name: string;
  avatar_file_bucket_id?: string;
  avatar_file_name?: string;
  created_at: string;
  joined_at: string;
  left_at: string;
  birthday: string;
  grade?: number;
}

export interface InitAccountResponse {
  organisation_id: string;
  identity_id: string;
  account_id: string;
}

export interface Entry {
  id: string;
  date: string;
  body: object | string;
  account_id: string;
  created_at: string;
}

export interface EntryAccount {
  id: string;
  account_id: string;
  account?: Account;
  entry_id: string;
  deleted_at?: string | null;
}

export interface Competence {
  id: string;
  name: string;
  competence_id: string;
  competence_type: string;
  organisation_id: string;
  grades: number[];
  color: string;
  curriculum_id: string;
  created_at: string;
}

export interface EntryAccountCompetence {
  id: string;
  level: number;
  account_id: string;
  account?: Account;
  entry_id: string;
  competence_id: string;
  competence?: Competence;
  created_at?: string;
  deleted_at?: string | null;
}

export interface EntryFile {
  id: string;
  entry_id: string;
  file_bucket_id: string;
  file_name: string;
  created_at?: string;
  deleted_at?: string | null;
}

export interface Event {
  id: string;
  image_file_bucket_id: string;
  image_file_name: string;
  organisation_id: string;
  title: string;
  body: string;
  starts_at: string;
  ends_at: string;
  recurrence?: string[];
  created_at: string;
  deleted_at?: string;
}

export interface EventCompetence {
  id: string;
  event_id: string;
  competence_id: string;
  created_at?: string;
}

export interface EntryEvent {
  id: string;
  entry_id: string;
  event_id: string;
  event?: Event;
  deleted_at?: string;
  created_at: string;
}

export interface Report {
  id: string;
  file_bucket_id?: string;
  file_name?: string;
  account_id: string;
  student_account_id: string;

  from: string;
  to: string;
  status: "pending" | "done" | "error";
  type: "report" | "subjects";
  meta?: string | object;

  filter_tags?: string[];

  created_at?: string;
}

export interface Tag {
  id: string;
  name: string;
  organisation_id: string;
  created_by: string;
  created_at: Date;
  deleted_at: Date;
}

export interface EntryTag {
  id: string;
  entry_id: string;
  tag_id: string;
  organisation_id: string;
  created_at: Date;
  deleted_at: Date;
}
