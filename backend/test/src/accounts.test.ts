import { getClientIdentity, getClientUser } from "./helper";
import { Account } from "../types";

test("policy identities can get their accounts", async () => {
  const { supabase: s1, user: u1, identity: i1 } = await getClientUser();
  const { supabase: s2, user: u2, identity: i2 } = await getClientUser();

  const a1 = await s1.from<Account>("accounts").select();
  const a2 = await s2.from<Account>("accounts").select();

  expect(a1.error).toBeNull();
  expect(a2.error).toBeNull();

  expect(a1.data).toHaveLength(1);
  expect(a2.data).toHaveLength(1);

  expect(a1.data[0].identity_id).toEqual(i1.id);
  expect(a2.data[0].identity_id).toEqual(i2.id);
});

test("policy owner,admin can crud accounts in their organisations", async () => {
  const {
    supabase: s1,
    user: u1,
    identity: i1,
    organisation: o1,
  } = await getClientUser();
  const { supabase: s2, user: u2, identity: i2 } = await getClientUser();
  const { supabase: st1, identity: it1 } = await getClientIdentity();

  let res = await s1.from("accounts").insert({
    role: "teacher",
    identity_id: it1.id,
    organisation_id: o1.id,
    first_name: "Test",
    last_name: "Test",
  } as Account);
  expect(res.error).toBeNull();

  res = await s2.from("accounts").insert({
    role: "teacher",
    organisation_id: o1.id,
    first_name: "Test",
    last_name: "Test",
  } as Account);
  expect(res.error).not.toBeNull();

  res = await st1.from("accounts").insert({
    role: "student",
    organisation_id: o1.id,
    first_name: "Test",
    last_name: "Test",
  } as Account);
  expect(res.error).not.toBeNull();
});

