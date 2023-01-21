import {
    createAccount,
    createTestEntry,
    createTestEntryAccount,
    createTestEntryAccountRaw,
    getClientUser,
    seeds
} from "./helper";

test("policy owner,admin,teacher can manage entry_accounts", async () => {
    const {supabase: s1, user: u1, organisation: o1, account: a1} = await getClientUser();
    const {supabase: s2, user: u2, account: a2} = await getClientUser();

    const entry = await createTestEntry(s1, a1.id);
    const {account: student} = await createAccount(s1, o1.id, 'student', false)

    // normal inserting should work
    await createTestEntryAccount(s1, entry.id, student.id);

    // should not be allowed to reference account from different organisation
    let res = await createTestEntryAccountRaw(s1, entry.id, a2.id)
    expect(res.error).not.toBeNull()
    expect(res.error.message).toContain('entry and account are not from the same organisation')

    // does not allow to use account from different organisation
    res = await createTestEntryAccountRaw(s2, entry.id, a1.id)
    expect(res.error).not.toBeNull()
    expect(res.error.message).toContain('entry and account are not from the same organisation')
})