import {
  createAccount,
  createTestEntry,
  createTestEntryRaw,
  getClientUser,
} from "./helper";

//TODO: update this test
test("some students can crud entries", async () => {
  const { supabase: s1, organisation: o1, account: a1 } = await getClientUser();
  const { supabase: s2 } = await getClientUser();
  const { supabase: t1, account: ta1 } = await createAccount(
    s1,
    o1.id,
    "teacher",
    true
  );
  const { supabase: st1, account: sa1 } = await createAccount(
    s1,
    o1.id,
    "student",
    true
  );

  //owner is allowed to create an entry
  await createTestEntry(s1, a1.id);

  // owner is allowed to create an entry with a different author
  await createTestEntry(s1, ta1.id);

  // teacher is allowed to create an entry with author=them
  await createTestEntry(t1, ta1.id);

  // someone from a org2 cannot insert as author=owner org1
  let res = await createTestEntryRaw(s2, a1.id);
  expect(res.error).not.toBeNull();

  // teachers cannot use an author different from them
  res = await createTestEntryRaw(t1, sa1.id);
  expect(res.error).not.toBeNull();
  res = await createTestEntryRaw(t1, a1.id);
  expect(res.error).not.toBeNull();

  // students cannot create entries
  res = await createTestEntryRaw(st1, sa1.id);
  expect(res.error).not.toBeNull();
});

test("teachers can read entries", async () => {
  const { supabase: s1, organisation: o1, account: a1 } = await getClientUser();
  const { supabase: s2, organisation: o2, account: a2 } = await getClientUser();
  const { supabase: t1, account: ta1 } = await createAccount(
    s1,
    o1.id,
    "teacher",
    true
  );
  const { supabase: t2, account: ta2 } = await createAccount(
    s2,
    o2.id,
    "teacher",
    true
  );

  await createTestEntry(s1, a1.id);
  await createTestEntry(s1, ta1.id);

  // teacher is allowed to read entries.
  let res = await t1.from("view_entries").select();
  expect(res.error).toBeNull();
  expect(res.data).toHaveLength(2);

  // teacher from another organisation should not see those entries.
  res = await t2.from("view_entries").select();
  expect(res.error).toBeNull();
  expect(res.data).toHaveLength(0);
});
