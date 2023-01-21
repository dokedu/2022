import {createClient, SupabaseClient} from "@supabase/supabase-js";
import {
    Account,
    Competence,
    Entry,
    EntryAccount,
    EntryAccountCompetence,
    EntryEvent,
    EntryFile, EntryTag,
    Event,
    EventCompetence,
    Identity,
    Report, Tag,
} from "../types";

import {Client} from "pg";
import {Seeds} from "../../../seeds/seeds";
import {PostgrestSingleResponse} from "@supabase/postgrest-js/src/lib/types";
import axios from "axios";
import ApiClient from "../types/ApiClient";

async function getDBClient() {
    const client = new Client({
        host: process.env.POSTGRES_HOST || "localhost",
        user: "postgres",
        password: "12341234",
    });
    await client.connect();
    return client;
}

export function getClient() {
    return new ApiClient(
        createClient(
            process.env.SUPABASE_URL || "http://localhost:8000",
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTYyNzIwODU0MCwiZXhwIjoxOTc0MzYzNzQwfQ.zcaQfHd3VA7XgJmdGfmV86OLVJT9s2MTmSy-e69BpUY"
        )
    );
}

export async function getClientUser() {
    const supabase = await getClient();
    let r = await supabase.auth.signUp({
        email: "User" + Math.random() + "@example.com",
        password: "12345678",
    });
    expect(r.error).toBeNull();

    let rInit = await supabase.initAccount();
    expect(rInit.error).toBeNull();

    // get the identity
    const identity = await supabase
        .from<Identity>("identities")
        .select()
        .eq("id", rInit.data.identity_id)
        .single();
    expect(identity.error).toBeNull();

    // get the organisation
    const organisation = await supabase
        .from<Identity>("organisations")
        .select()
        .eq("id", rInit.data.organisation_id)
        .single();
    expect(organisation.error).toBeNull();

    let mInit = await supabase.resetIndex(organisation.data.id);
    expect(mInit.error).toBeNull();

    // get the account
    const account = await supabase
        .from<Identity>("accounts")
        .select()
        .eq("id", rInit.data.account_id)
        .single();
    expect(account.error).toBeNull();

    return {
        supabase,
        user: r.user,
        identity: identity.data,
        organisation: organisation.data,
        account: account.data,
    };
}

export async function getClientIdentity() {
    const supabase = await getClient();
    let r = await supabase.auth.signUp({
        email: "User" + Math.random() + "@example.com",
        password: "12345678",
    });
    expect(r.error).toBeNull();

    let rInit = await supabase.initIdentity();
    expect(rInit.error).toBeNull();

    // get the identity
    const identity = await supabase
        .from<Identity>("identities")
        .select()
        .eq("id", rInit.data.identity_id)
        .single();
    expect(identity.error).toBeNull();

    return {supabase, identity: identity.data};
}

export async function createFullOrganisation() {
    const {
        supabase: s,
        user: u,
        identity: i,
        organisation: o,
        account: a
    } = await getClientUser();

    const {supabase: sAdmin, account: aAdmin} = await createAccount(s, o.id, 'admin', true)
    const {supabase: sTeacher, account: aTeacher} = await createAccount(s, o.id, 'teacher', true)
    const {supabase: sGuestTeacher, account: aGuestTeacher} = await createAccount(s, o.id, 'teacher_guest', true)
    const {supabase: sStudent, account: aStudent} = await createAccount(s, o.id, 'student', true)

    return {
        organisation: o,
        sOwner: s, aOwner: a,
        sAdmin, aAdmin,
        sTeacher, aTeacher,
        sGuestTeacher, aGuestTeacher,
        sStudent, aStudent
    }
}

export async function createAccount(
    supabase: SupabaseClient,
    organisation_id: string,
    role: string,
    createIdentity: boolean
) {
    let supabase2: SupabaseClient;
    let identity;
    if (createIdentity) {
        let res = await getClientIdentity();
        supabase2 = res.supabase;
        identity = res.identity;
    } else {
        supabase2 = await getClient();
    }

    let res = await supabase
        .from<Account>("accounts")
        .insert({
            role,
            identity_id: identity?.id,
            organisation_id,
            first_name: "Test",
            last_name: "Test",
        } as Account)
        .select("*")
        .single();
    expect(res.error).toBeNull();

    return {supabase: supabase2, identity: identity, account: res.data};
}

export let seeds: Seeds;
export let db: Client;
beforeAll(async () => {
    db = await getDBClient();
    seeds = new Seeds(db);
});
afterAll(async () => {
    await db.end();
});

export async function createTestEntryRaw(
    supabase: SupabaseClient,
    account_id: string
) {
    return await supabase
        .from<Entry>("entries")
        .insert({
            account_id,
            body: '{"text": "test entry body"}',
            date: new Date().toDateString(),
        })
        .select()
        .single();
}

export async function createTestEntry(
    supabase: SupabaseClient,
    account_id: string
) {
    const res = await createTestEntryRaw(supabase, account_id);
    expect(res.error).toBeNull();

    return res.data;
}

export async function createTestTag(    supabase: SupabaseClient,
                                        organisation_id: string,
                                        account_id: string, name: string) {
    const {data: testTag, error} = await supabase.from('tags').insert({
        name: name,
        organisation_id: organisation_id,
        created_by: account_id
    } as Tag).single()
    expect(error).toBeNull()
    expect(testTag.id).toBeDefined()

    return testTag
}

export async function createTestEntryTag(supabase: SupabaseClient, entry_id: string, tag_id: string, organisation_id: string) {
    const {data: testEntryTag, error} = await supabase.from('entry_tags').insert({
        entry_id: entry_id,
        tag_id: tag_id,
        organisation_id: organisation_id
    } as EntryTag).single()
    expect(error).toBeNull()
    expect(testEntryTag.id).toBeDefined()

    return testEntryTag
}

export async function createTestEntryAccount(
    supabase: SupabaseClient,
    entry_id: string,
    account_id: string
) {
    const res = await supabase
        .from<EntryAccount>("entry_accounts")
        .insert({
            account_id,
            entry_id,
        })
        .select()
        .single();
    expect(res.error).toBeNull();

    return res.data;
}

export async function createTestEntryAccountRaw(
    supabase: SupabaseClient,
    entry_id: string,
    account_id: string
) {
    return await supabase
        .from<EntryAccount>("entry_accounts")
        .insert({
            account_id,
            entry_id,
        })
        .select()
        .single();
}

export async function createTestCompetenceRaw(
    supabase: SupabaseClient,
    organisation_id: string,
    name = "test competence",
    parent_id: string = undefined
) {
    return await supabase
        .from<Competence>("competences")
        .insert({
            name,
            competence_type: "competence",
            organisation_id: organisation_id,
            grades: [1],
            color: "yes",
            competence_id: parent_id,
        })
        .select()
        .single();
}

export async function createTestCompetence(
    supabase: SupabaseClient,
    organisation_id: string,
    name = "test competence",
    parent_id: string = undefined
) {
    const res = await createTestCompetenceRaw(
        supabase,
        organisation_id,
        name,
        parent_id
    );
    expect(res.error).toBeNull();

    return res.data;
}

export async function createTestEntryCompetenceRaw(
    supabase: SupabaseClient,
    account_id: string,
    entry_id: string,
    competence_id: string
) {
    return await supabase
        .from<EntryAccountCompetence>("entry_account_competences")
        .insert({
            level: 3,
            account_id,
            entry_id,
            competence_id,
        })
        .select()
        .single();
}

export async function createTestEntryCompetence(
    supabase: SupabaseClient,
    account_id: string,
    entry_id: string,
    competence_id: string
) {
    const res = await createTestEntryCompetenceRaw(
        supabase,
        account_id,
        entry_id,
        competence_id
    );
    expect(res.error).toBeNull();

    return res.data;
}

export async function uploadTestFile(
    supabase: SupabaseClient,
    organisation_id: string
) {
    let res = await supabase.storage
        .from("org_" + organisation_id)
        .upload(`entries/${Math.random()}/test1.png`, "fc1");
    expect(res.error).toBeNull();
    return res.data;
}

export async function createTestEntryFileRaw(
    supabase: SupabaseClient,
    entry_id: string,
    file_bucket_id: string,
    file_name: string
) {
    return await supabase
        .from<EntryFile>("entry_files")
        .insert({
            entry_id,
            file_name,
            file_bucket_id,
        })
        .select()
        .single();
}

export async function createTestEntryFile(
    supabase: SupabaseClient,
    entry_id: string,
    file_bucket_id: string,
    file_name: string
) {
    const res = await createTestEntryFileRaw(
        supabase,
        entry_id,
        file_bucket_id,
        file_name
    );
    expect(res.error).toBeNull();

    return res.data;
}

export async function createTestEventRaw(
    supabase: SupabaseClient,
    organisation_id: string
): Promise<PostgrestSingleResponse<Event>> {
    const a = await supabase.storage
        .from("org_" + organisation_id)
        .upload("/events/" + Math.random().toString(), "1234");
    if (a.error) return a as any as PostgrestSingleResponse<Event>;

    const fileS = a.data.Key.split("/");
    const bucket = fileS.shift();
    const name = fileS.join("/");

    return supabase
        .from<Event>("events")
        .insert({
            title: "testEvent",
            image_file_bucket_id: bucket,
            image_file_name: name,
            organisation_id,
            body: "1234",
            starts_at: new Date().toDateString(),
            ends_at: new Date(2050, 1, 1).toDateString(),
        })
        .select()
        .single();
}

export async function createTestEvent(
    supabase: SupabaseClient,
    organisation_id: string
) {
    const res = await createTestEventRaw(supabase, organisation_id);
    expect(res.error).toBeNull();
    return res.data as Event;
}

export async function createTestEntryEventRaw(
    supabase: SupabaseClient,
    entry_id: string,
    event_id: string
) {
    return await supabase
        .from<EntryEvent>("entry_events")
        .insert({
            entry_id,
            event_id,
        })
        .select()
        .single();
}

export async function createTestEntryEvent(
    supabase: SupabaseClient,
    entry_id: string,
    event_id: string
) {
    const res = await createTestEntryEventRaw(supabase, entry_id, event_id);
    expect(res.error).toBeNull();

    return res.data;
}

export async function createTestReportRaw(
    supabase: SupabaseClient,
    account_id: string
): Promise<PostgrestSingleResponse<Report>> {
    return supabase
        .from<Report>("reports")
        .insert({
            account_id,
            student_account_id: account_id,
            type: "report",
            from: new Date().toDateString(),
            to: new Date(2000, 1, 1).toDateString(),
            meta: {},
        })
        .select()
        .single();
}

export async function createTestReport(
    supabase: SupabaseClient,
    account_id: string
) {
    const res = await createTestReportRaw(supabase, account_id);
    expect(res.error).toBeNull();

    return res.data;
}

export async function createTestEventCompetenceRaw(
    supabase: SupabaseClient,
    event_id: string,
    competence_id: string
) {
    return await supabase
        .from<EventCompetence>("event_competences")
        .insert({
            competence_id,
            event_id,
        })
        .select()
        .single();
}

export async function createTestEventCompetence(
    supabase: SupabaseClient,
    event_id: string,
    competence_id: string
) {
    const res = await createTestEventCompetenceRaw(
        supabase,
        event_id,
        competence_id
    );
    expect(res.error).toBeNull();

    return res.data;
}

// mailhog helper
const mailhogUrl = `${process.env.MAILHOG_URL || "http://localhost:8025"}`;

export async function mailhogReset() {
    return axios.delete(mailhogUrl + "/api/v1/messages");
}

type MailhogGetMessagesResponse = {
    total: number;
    items: {
        ID: string;
        From: string;
        To: {
            Mailbox: string;
            Domain: string;
        }[];
        Content: {
            Body: string;
        };
    }[];
};

export async function mailhogGetMessages(): Promise<MailhogGetMessagesResponse> {
    const res = await axios.get(mailhogUrl + "/api/v2/messages");

    return res.data;
}
