import {getClientUser, seeds} from "./helper";
import {Entry} from "../types";

it('correctly uses seeds to seed the db', async () => {
    const {supabase, account} = await getClientUser();

    await seeds.runTestSeed(account.id);

    const res = await supabase.from<Entry>('entries').select().single()
    expect(res.error).toBeNull()
    expect(typeof res.data.body).toEqual('object')
    expect(JSON.stringify(res.data.body)).toContain('this is a test, coming from a seed.')
})