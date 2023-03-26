import { getClientUser } from "./helper";
import { Identity } from "../types";

test("policy students can get their identities", async () => {
  const { supabase: s1, user: u1 } = await getClientUser();
  const { supabase: s2, user: u2 } = await getClientUser();

  const i1 = await s1.from<Identity>("identities").select();
  const i2 = await s2.from<Identity>("identities").select();

  expect(i1.error).toBeNull();
  expect(i2.error).toBeNull();

  expect(i1.data).toHaveLength(1);
  expect(i2.data).toHaveLength(1);

  expect(i1.data[0].user_id).toEqual(u1.id);
  expect(i2.data[0].user_id).toEqual(u2.id);
});
