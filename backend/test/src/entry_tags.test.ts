import {createFullOrganisation, createTestEntry, createTestEntryTag, createTestTag, getClientUser} from "./helper";
import {EntryTag, Tag} from "../types";
import {SupabaseClient} from "@supabase/supabase-js";

test("entry_tag permissions", async () => {
    const org1 = await createFullOrganisation()
    const org2 = await createFullOrganisation()

    const testTag = await createTestTag(org1.sOwner, org1.organisation.id, org1.aOwner.id, "TestTag")
    const testEntry = await createTestEntry(org1.sOwner, org1.aOwner.id)
    const testEntryTag = await createTestEntryTag(org1.sOwner, testEntry.id, testTag.id, org1.organisation.id)

    // org1 can read the tag
    await canReadEntryTag(org1.sOwner, true)
    await canReadEntryTag(org1.sAdmin, true)
    await canReadEntryTag(org1.sTeacher, true)
    await canReadEntryTag(org1.sGuestTeacher, true)
    await canReadEntryTag(org1.sStudent, false)

    //org2 cannot read the tag
    await canReadEntryTag(org2.sOwner, false)
    await canReadEntryTag(org2.sAdmin, false)
    await canReadEntryTag(org2.sTeacher, false)
    await canReadEntryTag(org2.sGuestTeacher, false)
    await canReadEntryTag(org2.sStudent, false)

    // org1 can create tags
    await canCreateEntryTag(org1.sOwner, org1.aOwner.id, true)
    await canCreateEntryTag(org1.sAdmin, org1.aAdmin.id, true)
    await canCreateEntryTag(org1.sTeacher, org1.aTeacher.id, true)
    await canCreateEntryTag(org1.sGuestTeacher, org1.aGuestTeacher.id, true)
    await canCreateEntryTag(org1.sStudent, org1.aStudent.id, false)

    // org2 cannot create tags
    await canCreateEntryTag(org2.sOwner, org2.aOwner.id, false)
    await canCreateEntryTag(org2.sOwner, org1.aOwner.id, false)
    await canCreateEntryTag(org2.sAdmin, org2.aAdmin.id, false)
    await canCreateEntryTag(org2.sTeacher, org2.aTeacher.id, false)
    await canCreateEntryTag(org2.sGuestTeacher, org2.aGuestTeacher.id, false)
    await canCreateEntryTag(org2.sStudent, org2.aStudent.id, false)

    // org1 can update tags
    await canUpdateEntryTag(org1.sOwner, org1.aOwner.id, true)
    await canUpdateEntryTag(org1.sAdmin, org1.aAdmin.id, true)
    await canUpdateEntryTag(org1.sTeacher, org1.aTeacher.id, true)
    await canUpdateEntryTag(org1.sGuestTeacher, org1.aGuestTeacher.id, true)
    await canUpdateEntryTag(org1.sStudent, org1.aStudent.id, false)

    // org2 cannot update tags
    await canUpdateEntryTag(org2.sOwner, org2.aOwner.id, false)
    await canUpdateEntryTag(org2.sOwner, org1.aOwner.id, false)
    await canUpdateEntryTag(org2.sAdmin, org2.aAdmin.id, false)
    await canUpdateEntryTag(org2.sTeacher, org2.aTeacher.id, false)
    await canUpdateEntryTag(org2.sGuestTeacher, org2.aGuestTeacher.id, false)
    await canUpdateEntryTag(org2.sStudent, org2.aStudent.id, false)

    //org1 can delete tags
    await canDeleteEntryTag(org1.sOwner, true)
    await canDeleteEntryTag(org1.sAdmin, true)
    await canDeleteEntryTag(org1.sTeacher, true)
    await canDeleteEntryTag(org1.sGuestTeacher, true)
    await canDeleteEntryTag(org1.sStudent, false)

    // org2 cannot delete tags
    await canDeleteEntryTag(org2.sOwner, false)
    await canDeleteEntryTag(org2.sAdmin, false)
    await canDeleteEntryTag(org2.sTeacher, false)
    await canDeleteEntryTag(org2.sGuestTeacher, false)
    await canDeleteEntryTag(org2.sStudent, false)

    async function canReadEntryTag(supabase: SupabaseClient, shouldWork: boolean) {
        const {data, error} = await supabase.from('entry_tags').select().eq('id', testEntryTag.id).single()
        if (shouldWork) {
            expect(error).toBeNull()
            expect(data).toBeDefined()
            expect(data.id).toEqual(testEntryTag.id)
        } else {
            expect(error).toBeDefined()
            expect(data).toBeNull()
        }
    }
    async function canCreateEntryTag(supabase: SupabaseClient, account: string, shouldWork: boolean) {
        const entry = await createTestEntry(org1.sOwner, org1.aOwner.id)

        const {data, error} = await supabase.from('entry_tags').insert({
            entry_id: entry.id,
            tag_id: testTag.id,
            organisation_id: org1.organisation.id,
        } as EntryTag).single()
        if (shouldWork) {
            expect(error).toBeNull()
            expect(data.id).toBeDefined()
        } else {
            expect(error).toBeDefined()
        }
    }
    async function canUpdateEntryTag(supabase: SupabaseClient, account: string, shouldWork: boolean) {
        const entry = await createTestEntry(org1.sOwner, org1.aOwner.id)

        await org1.sOwner.from('entry_tags').update({
            entry_id: testEntry.id
        } as EntryTag).eq('id', testEntryTag.id).single()

        const {error} = await supabase.from('entry_tags').update({
            entry_id: entry.id,
        } as EntryTag).eq('id', testEntryTag.id).single()

        const {data: readTag, error: errRead} = await org1.sOwner.from('entry_tags').select().eq('id', testEntryTag.id).single()
        expect(errRead).toBeNull()

        if (shouldWork) {
            expect(error).toBeNull()
            expect(readTag.entry_id).toEqual(entry.id)
        } else {
            expect(error).toBeDefined()
            expect(readTag.entry_id).toEqual(testEntry.id)
        }
    }
    async function canDeleteEntryTag(supabase: SupabaseClient, shouldWork: boolean) {
        const testEntry = await createTestEntry(org1.sOwner, org1.aOwner.id)
        const testEntryTag = await createTestEntryTag(org1.sOwner, testEntry.id, testTag.id, org1.organisation.id)

        const {error, data} = await supabase.from('entry_tags').delete().eq('id', testEntryTag.id)
        expect(error).toBeNull()

        const {data: readTag, error: errRead} = await org1.sOwner.from('entry_tags').select().eq('id', testEntryTag.id).single()

        if (shouldWork) {
            expect(data.length).toEqual(1)
            expect(errRead).toBeDefined()
        } else {
            expect(data.length).toEqual(0)
            expect(errRead).toBeNull()
        }
    }
})

test('tag, entry, entry_tag must be from the same organisation', async () => {
    const { supabase: s1, organisation: o1, account: a1 } = await getClientUser();
    const { supabase: s2, organisation: o2, account: a2 } = await getClientUser();

    const testTag = await createTestTag(s1, o1.id, a1.id, "TestTag")
    const testTagO2 = await createTestTag(s2, o2.id, a2.id, "TestTag")
    const testEntry = await createTestEntry(s1, a1.id)
    const testEntryO2 = await createTestEntry(s2, a2.id)

    // create tag with o2
    const { error } = await s1.from('entry_tags').insert({
        entry_id: testEntry.id,
        tag_id: testTag.id,
        organisation_id: o2.id,
    } as EntryTag).single()
    expect(error).toBeDefined()
    expect(error.message).toContain("must be in the same organisation")

    const { error: error2 } = await s1.from('entry_tags').insert({
        entry_id: testEntryO2.id,
        tag_id: testTag.id,
        organisation_id: o1.id,
    } as EntryTag).single()
    expect(error2).toBeDefined()
    expect(error2.message).toContain("must be in the same organisation")

    const { error: error3 } = await s1.from('entry_tags').insert({
        entry_id: testEntry.id,
        tag_id: testTagO2.id,
        organisation_id: o1.id,
    } as EntryTag).single()
    expect(error3).toBeDefined()
    expect(error3.message).toContain("must be in the same organisation")
})