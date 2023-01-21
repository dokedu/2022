import {
    createAccount, createTestCompetence,
    createTestEntry,
    createTestEntryAccount,
    createTestEntryCompetence,
    db,
    getClientUser
} from "./helper";
import * as fs from 'fs'

test("we can merge two students via script", async () => {
    const { supabase: s1, organisation: o1, account: a1 } = await getClientUser();
    const { supabase: t1, account: student1 } = await createAccount(
        s1,
        o1.id,
        "student",
        false
    );

    const { supabase: t2, account: student2 } = await createAccount(
        s1,
        o1.id,
        "student",
        false
    );

    const { supabase: t3, account: student3 } = await createAccount(
        s1,
        o1.id,
        "student",
        false
    );

    const { supabase: t4, account: student4 } = await createAccount(
        s1,
        o1.id,
        "student",
        false
    );

    await s1.from('accounts').update({ first_name: "uuu" }).eq("id", student3.id)


    let entry = await createTestEntry(s1, a1.id);
    await createTestEntryAccount(s1, entry.id, student1.id);

    let entry2 = await createTestEntry(s1, a1.id);
    await createTestEntryAccount(s1, entry2.id, student2.id);

    let entry3 = await createTestEntry(s1, a1.id);
    await createTestEntryAccount(s1, entry3.id, student1.id);


    let res = await s1.from('entry_accounts').select("id", { count: "exact" }).eq('account_id', student1.id)
    expect(res.count).toEqual(2)

    res = await s1.from('entry_accounts').select("id", { count: "exact" }).eq('account_id', student2.id)
    expect(res.count).toEqual(1)

    // delete from
    await s1.from('accounts').delete().eq('id', student1.id)

    // execute the script
    let script = fs.readFileSync('../scripts/student-merge.sql').toString()
    await db.query(`
    begin;
    ${script};
    
    select pg_temp.merge_students('${student1.id}', '${student2.id}');
    commit;
    `);

    res = await s1.from('entry_accounts').select("id", { count: "exact" }).eq('account_id', student1.id)
    expect(res.count).toEqual(0)

    res = await s1.from('entry_accounts').select("id", { count: "exact" }).eq('account_id', student2.id)
    expect(res.count).toEqual(3)

    // doesn't work if not deleted

    const merge = async () => {
        await db.query(`
        rollback;
    begin;
    ${script};
    
    select pg_temp.merge_students('${student3.id}', '${student2.id}');
    commit;
    `)
    }
    await expect(
        merge()
    ).rejects.toThrow("from_account must be deleted")

    await s1.from('accounts').delete().eq('id', student3.id)

    await expect(
        merge()
    ).rejects.toThrow("first_name and last_name must be the same")

    await s1.from('accounts').update({ first_name: "Test" }).eq("id", student3.id)

    await merge()


    // try it if there are duplicates among them.

    let entry4 = await createTestEntry(s1, a1.id);
    let competence = await createTestCompetence(s1, o1.id, "test")
    await createTestEntryAccount(s1, entry4.id, student2.id);
    await createTestEntryAccount(s1, entry4.id, student4.id);

    await createTestEntryCompetence(s1, student2.id, entry4.id, competence.id)
    await createTestEntryCompetence(s1, student4.id, entry4.id, competence.id)

    await s1.from('accounts').delete().eq('id', student4.id)
    await db.query(`
        rollback;
    begin;
    ${script};
    
    select pg_temp.merge_students('${student4.id}', '${student2.id}');
    commit;
    `)

    res = await s1.from('accounts').select('id', { count: "exact" }).eq('organisation_id', o1.id)
    expect(res.count).toEqual(2)


})