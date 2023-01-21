import {
    createAccount,
    createTestCompetence,
    createTestEvent,
    createTestEventCompetenceRaw,
    getClientUser
} from "./helper";

it('allows admins,owners,teachers to manage event_competences', async () => {
    const { supabase: s1, organisation: o1 } = await getClientUser();
    let event = await createTestEvent(s1, o1.id);

    const testingTable = [
        ['owner', true],
        ['admin', true],
        ['teacher', true],
        ['teacher_guest', false],
        ['student', false],
    ]

    for (let test of testingTable) {
        const { supabase: s, account: a } = await createAccount(s1, o1.id, test[0] as string, true)
        let competence = await createTestCompetence(s1, o1.id);
        let res = await createTestEventCompetenceRaw(s, event.id, competence.id);

        if (test[1]) {
            expect(res.error).toBeNull()
            expect(res.data.id).not.toEqual(undefined)
        } else {
            expect(res.error).not.toBeNull()
        }
    }
})

it('does not allow accounts from other organisations to manage event_competences', async () => {
    const { supabase: s1, organisation: o1 } = await getClientUser();
    const { supabase: s2, organisation: o2 } = await getClientUser();

    let event = await createTestEvent(s1, o1.id);
    let competence = await createTestCompetence(s1, o1.id);

    // roles from different org
    for (let role of ['owner', 'admin', 'teacher', 'teacher_guest', 'student']) {
        const { supabase: s } = await createAccount(s2, o2.id, role, true)
        let res = await createTestEventCompetenceRaw(s, event.id, competence.id);
        expect(res.error).not.toBeNull()
    }
})

it('does not allow competences from other organisations when creating event_competences', async () => {
    const { supabase: s1, organisation: o1 } = await getClientUser();
    const { supabase: s2, organisation: o2 } = await getClientUser();

    let event = await createTestEvent(s1, o1.id);
    let competence = await createTestCompetence(s2, o2.id);

    let res = await createTestEventCompetenceRaw(s1, event.id, competence.id);
    expect(res.error).not.toBeNull()
    expect(res.error.message).toEqual('event, competence are not from the same organisation')
})