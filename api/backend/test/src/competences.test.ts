import {createTestCompetence, getClientUser} from "./helper";
import {Competence} from "../types";

test("get_competence_tree allows retrieval of competence parents", async () => {
    const {supabase: s1, organisation: o1, account: a1} = await getClientUser();
    const {supabase: s2} = await getClientUser();

    const a = await createTestCompetence(s1, o1.id, 'A')
    const aa = await createTestCompetence(s1, o1.id, 'A A', a.id)
    const aaa = await createTestCompetence(s1, o1.id, 'A A A', aa.id)
    const aab = await createTestCompetence(s1, o1.id, 'A A B', aa.id)
    const ab = await createTestCompetence(s1, o1.id, 'A B', a.id)
    const aba = await createTestCompetence(s1, o1.id, 'A B A', ab.id)
    const abaa = await createTestCompetence(s1, o1.id, 'A B A A', aba.id)
    const abab = await createTestCompetence(s1, o1.id, 'A B A B', aba.id)

    const table: { [key: string]: string[] } = {}
    table[a.id] = ['A']
    table[aa.id] = ['A', 'A A']
    table[aaa.id] = ['A', 'A A', 'A A A']
    table[aab.id] = ['A', 'A A', 'A A B']
    table[ab.id] = ['A', 'A B']
    table[aba.id] = ['A', 'A B', 'A B A']
    table[abaa.id] = ['A', 'A B', 'A B A', 'A B A A']
    table[abab.id] = ['A', 'A B', 'A B A', 'A B A B']

    for (let [competenceId, data] of Object.entries(table)) {
        let res = await s1.rpc<Competence>('get_competence_tree', {_competence_id: competenceId}).select()
        expect(res.error).toBeNull()
        expect(res.data.map(a => a.name)).toEqual(data.reverse())
    }

})

test("get_competence_tree does not expose competences to other orgs", async () => {
    const {supabase: s1, organisation: o1, account: a1} = await getClientUser();
    const {supabase: s2} = await getClientUser();

    const competence = await createTestCompetence(s1, o1.id, 'A')
    let res = await s2.rpc<Competence>('get_competence_tree', {_competence_id: competence.id}).select()
    expect(res.error).not.toBeNull()
    expect(res.error.message).toEqual('competence not found')
})