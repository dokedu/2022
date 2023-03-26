import {getClientUser} from "./helper";

it('allows a user to upload files', async () => {
    const { supabase: s1, organisation: o1} = await getClientUser();
    const { supabase: s2, organisation: o2} = await getClientUser();
    let res = await s1.storage.from('org_' + o1.id).upload('entries/entryID/test1.png', 'fc1')
    expect(res.error).toBeNull()

    // does not allow to upload to another organisation
    res = await s2.storage.from('org_' + o1.id).upload('entries/entryID/test1.png', 'fc1')
    expect(res.error).not.toBeNull()
})