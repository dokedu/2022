import {createFullOrganisation, createTestTag, getClientUser} from "./helper";
import {Tag} from "../types";
import {SupabaseClient} from "@supabase/supabase-js";

test("tag permissions", async () => {
    const org1 = await createFullOrganisation()
    const org2 = await createFullOrganisation()

    const testTag = await createTestTag(org1.sOwner, org1.organisation.id, org1.aOwner.id, "TestTag")

    // org1 can read the tag
    await canReadTag(org1.sOwner, true)
    await canReadTag(org1.sAdmin, true)
    await canReadTag(org1.sTeacher, true)
    await canReadTag(org1.sGuestTeacher, true)
    await canReadTag(org1.sStudent, true)

    //org2 cannot read the tag
    await canReadTag(org2.sOwner, false)
    await canReadTag(org2.sAdmin, false)
    await canReadTag(org2.sTeacher, false)
    await canReadTag(org2.sGuestTeacher, false)
    await canReadTag(org2.sStudent, false)

    // org1 can create tags
    await canCreateTag(org1.sOwner, org1.aOwner.id, true)
    await canCreateTag(org1.sAdmin, org1.aAdmin.id, true)
    await canCreateTag(org1.sTeacher, org1.aTeacher.id, true)
    await canCreateTag(org1.sGuestTeacher, org1.aGuestTeacher.id, false)
    await canCreateTag(org1.sStudent, org1.aStudent.id, false)

    // org2 cannot create tags
    await canCreateTag(org2.sOwner, org2.aOwner.id, false)
    await canCreateTag(org2.sOwner, org1.aOwner.id, false)
    await canCreateTag(org2.sAdmin, org2.aAdmin.id, false)
    await canCreateTag(org2.sTeacher, org2.aTeacher.id, false)
    await canCreateTag(org2.sGuestTeacher, org2.aGuestTeacher.id, false)
    await canCreateTag(org2.sStudent, org2.aStudent.id, false)

    // org1 can update tags
    await canUpdateTag(org1.sOwner, org1.aOwner.id, true)
    await canUpdateTag(org1.sAdmin, org1.aAdmin.id, true)
    await canUpdateTag(org1.sTeacher, org1.aTeacher.id, true)
    await canUpdateTag(org1.sGuestTeacher, org1.aGuestTeacher.id, false)
    await canUpdateTag(org1.sStudent, org1.aStudent.id, false)

    // org2 cannot update tags
    await canUpdateTag(org2.sOwner, org2.aOwner.id, false)
    await canUpdateTag(org2.sOwner, org1.aOwner.id, false)
    await canUpdateTag(org2.sAdmin, org2.aAdmin.id, false)
    await canUpdateTag(org2.sTeacher, org2.aTeacher.id, false)
    await canUpdateTag(org2.sGuestTeacher, org2.aGuestTeacher.id, false)
    await canUpdateTag(org2.sStudent, org2.aStudent.id, false)

    //org1 can delete tags
    await canDeleteTag(org1.sOwner, true)
    await canDeleteTag(org1.sAdmin, true)
    await canDeleteTag(org1.sTeacher, true)
    await canDeleteTag(org1.sGuestTeacher, false)
    await canDeleteTag(org1.sStudent, false)

    // org2 cannot delete tags
    await canDeleteTag(org2.sOwner, false)
    await canDeleteTag(org2.sAdmin, false)
    await canDeleteTag(org2.sTeacher, false)
    await canDeleteTag(org2.sGuestTeacher, false)

    async function canReadTag(supabase: SupabaseClient, shouldWork: boolean) {
        const {data, error} = await supabase.from('tags').select().eq('id', testTag.id).single()
        if (shouldWork) {
            expect(error).toBeNull()
            expect(data).toBeDefined()
            expect(data.id).toEqual(testTag.id)
        } else {
            expect(error).toBeDefined()
            expect(data).toBeNull()
        }
    }
    async function canCreateTag(supabase: SupabaseClient, account: string, shouldWork: boolean) {
        const {data, error} = await supabase.from('tags').insert({
            name: "ABC" + Math.random(),
            created_by: account,
            organisation_id: org1.organisation.id
        } as Tag).single()
        if (shouldWork) {
            expect(error).toBeNull()
            expect(data.id).toBeDefined()
        } else {
            expect(error).toBeDefined()
        }
    }
    async function canUpdateTag(supabase: SupabaseClient, account: string, shouldWork: boolean) {
        const newName = Math.random().toString()

        await org1.sOwner.from('tags').update({
            name: "TestTag",
            created_by: org1.aOwner.id
        } as Tag).eq('id', testTag.id).single()

        const {error} = await supabase.from('tags').update({
            name: newName,
            created_by: account
        } as Tag).eq('id', testTag.id).single()

        const {data: readTag, error: errRead} = await org1.sOwner.from('tags').select().eq('id', testTag.id).single()
        expect(errRead).toBeNull()

        if (shouldWork) {
            expect(error).toBeNull()
            expect(readTag.name).toEqual(newName)
        } else {
            expect(error).toBeDefined()
            expect(readTag.name).toEqual("TestTag")
        }
    }
    async function canDeleteTag(supabase: SupabaseClient, shouldWork: boolean) {
        const {data: testTag1, error: err} = await org1.sOwner.from('tags').insert({
            name: "TestTag" + Math.random(),
            organisation_id: org1.organisation.id,
            created_by: org1.aOwner.id
        } as Tag).eq('id', testTag.id).single()
        expect(err).toBeNull()
        expect(testTag1.id).toBeDefined()

        const {error, data} = await supabase.from('tags').delete().eq('id', testTag1.id)
        expect(error).toBeNull()

        const {data: readTag, error: errRead} = await org1.sOwner.from('tags').select().eq('id', testTag1.id).single()

        if (shouldWork) {
            expect(data.length).toEqual(1)
            expect(errRead).toBeDefined()
        } else {
            expect(data.length).toEqual(0)
            expect(errRead).toBeNull()
        }

    }
})

test('tag and created_by user must be from the same organisation', async () => {
    const { supabase: s1, organisation: o1, account: a1 } = await getClientUser();
    const { supabase: s2, organisation: o2, account: a2 } = await getClientUser();

    // create tag with o2
    const { data: tag, error } = await s1.from('tags').insert({
        name: "TestTag" + Math.random(),
        organisation_id: o2.id,
        created_by: a1.id
    } as Tag).single()
    expect(error).toBeDefined()
    expect(error.message).toContain("must be in the same organisation")

    const { data: tag2, error: error2 } = await s1.from('tags').insert({
        name: "TestTag" + Math.random(),
        organisation_id: o1.id,
        created_by: a2.id
    } as Tag).single()
    expect(error2).toBeDefined()
    expect(error2.message).toContain("must be in the same organisation")
})

test('tag created_by must always be the current user', async () => {
    const org = await createFullOrganisation();
    const { data: tag, error: error } = await org.sOwner.from('tags').insert({
        name: "TestTag" + Math.random(),
        organisation_id: org.organisation.id,
        created_by: org.aAdmin.id
    } as Tag).single()
    expect(error).toBeDefined()
    expect(error.message).toContain("must be one of the accounts from the current user")
})