import {
    createAccount, createTestCompetence,
    createTestEntry,
    createTestEntryCompetence, createTestEntryCompetenceRaw,
    getClientUser,
} from "./helper";

test("policy owner,admin,teacher can manage entry_account_competences", async () => {
    const {supabase: s1, user: u1, organisation: o1, account: a1} = await getClientUser();
    const {supabase: s2, user: u2, account: a2} = await getClientUser();

    const entry = await createTestEntry(s1, a1.id);
    const {account: student} = await createAccount(s1, o1.id, 'student', false)
    const competence = await createTestCompetence(s1, o1.id)

    // normal inserting should work
    await createTestEntryCompetence(s1, student.id, entry.id, competence.id);

    // should not be allowed to reference account from different organisation
    let res = await createTestEntryCompetenceRaw(s1, a2.id, entry.id, competence.id)
    expect(res.error).not.toBeNull()
    expect(res.error.message).toContain('entry, account and competence are not from the same organisation')

    // does not allow to use account from different organisation
    res = await createTestEntryCompetenceRaw(s2, a2.id, entry.id, competence.id)
    expect(res.error).not.toBeNull()
    expect(res.error.message).toContain('entry, account and competence are not from the same organisation')
})