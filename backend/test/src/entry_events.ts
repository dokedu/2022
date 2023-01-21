import {
    createAccount,
    createTestEntry,
    createTestEntryEventRaw,
    createTestEvent,
    createTestEventRaw,
    getClientUser
} from "./helper";

it('allows admins,owners,teachers to manage entry_events', async () => {
    const {supabase: s1, organisation: o1, account: a1} = await getClientUser();
    let event = await createTestEvent(s1, o1.id);
    let entry = await createTestEntry(s1, a1.id);

    const testingTable = [
        ['owner', true],
        ['admin', true],
        ['teacher', true],
        ['teacher_guest', false],
        ['student', false],
    ]

    for (let test of testingTable) {
        const {supabase: s, account: a} = await createAccount(s1, o1.id, test[0] as string, true)
        const res = await createTestEntryEventRaw(s, entry.id, event.id)
        if (test[1]) {
            expect(res.error).toBeNull()
            expect(res.data.id).not.toEqual(undefined)
        } else {
            expect(res.error).not.toBeNull()
        }
    }
})

it('does not allow accounts from other organisations to manage entry_events', async () => {
    const {supabase: s1, organisation: o1, account: a1} = await getClientUser();
    let event = await createTestEvent(s1, o1.id);
    let entry = await createTestEntry(s1, a1.id);

    const {supabase: s2, organisation: o2} = await getClientUser();

    // roles from different org
    for (let role of ['owner', 'admin', 'teacher', 'teacher_guest', 'student']) {
        const {supabase: s} = await createAccount(s2, o2.id, role, true)
        const res = await createTestEntryEventRaw(s, entry.id, event.id)
        expect(res.error).not.toBeNull()
    }
})