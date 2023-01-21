import {getClient, getClientUser} from "./helper";

test("401 on unauthenticated requests", async () => {
    const s = getClient();

    const res = await s.meiliSearch("abcd")
    expect(res.error).not.toBeNull()
    expect(res.error.status).toEqual(401)
})

test("to find things", async () => {
    const {supabase, organisation: o} = await getClientUser();

    const res = await supabase.meiliSearch(o.id)
    expect(res.error).toBeNull()
    expect(res.data.hits).toHaveLength(0)
})