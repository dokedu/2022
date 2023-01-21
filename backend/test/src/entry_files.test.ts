import {
    createAccount,
    createTestCompetence,
    createTestEntry,
    createTestEntryAccount,
    createTestEntryAccountRaw,
    createTestEntryCompetence,
    createTestEntryCompetenceRaw,
    createTestEntryFile,
    createTestEntryFileRaw,
    getClientUser,
    seeds,
    uploadTestFile
} from "./helper";

test("policy owner,admin,teacher can manage entry_files", async () => {
    const {supabase: s1, user: u1, organisation: o1, account: a1} = await getClientUser();
    const {supabase: s2, user: u2, account: a2} = await getClientUser();

    const entry = await createTestEntry(s1, a1.id);
    const file = await uploadTestFile(s1, o1.id)
    const key = file.Key.split('/')

    const bucket = key.shift()
    const file_name = key.join('/')

    // normal inserting should work
    await createTestEntryFile(s1, entry.id, bucket, file_name);

    // does not allow to use entry from different organisation
    let res = await createTestEntryFileRaw(s2, entry.id, bucket, file_name)
    expect(res.error).not.toBeNull()
    expect(res.error.message).toContain('entry, file are not from the same organisation')
})