import {
  createAccount,
  createTestEvent,
  createTestEventRaw,
  getClientUser,
} from "./helper";
import { Event } from "../types";

it("allows admins,owners,teachers to manage events", async () => {
  const { supabase: s1, organisation: o1 } = await getClientUser();

  const testingTable = [
    ["owner", true],
    ["admin", true],
    ["teacher", true],
    ["teacher_guest", false],
    ["student", false],
  ];

  for (let test of testingTable) {
    const { supabase: s, account: a } = await createAccount(
      s1,
      o1.id,
      test[0] as string,
      true
    );
    let res = await createTestEventRaw(s, o1.id);

    if (test[1]) {
      expect(res.error).toBeNull();
      expect(res.data.id).not.toEqual(undefined);
    } else {
      expect(res.error).not.toBeNull();
    }
  }
});

it("allows admins to update events", async () => {
  const { supabase: s1, organisation: o1 } = await getClientUser();
  const { supabase: s, account: a } = await createAccount(
    s1,
    o1.id,
    "admin",
    true
  );
  let event = await createTestEvent(s, o1.id);

  let res = await s
    .from<Event>("events")
    .update({ id: event.id, deleted_at: new Date().toISOString() })
    .eq("id", event.id)
    .single();
  expect(res.error).toBeNull();
  expect(res.data);
});

it("allows admins to create new events", async () => {
  const { supabase: s1, organisation: o1 } = await getClientUser();
  const { supabase: s } = await createAccount(s1, o1.id, "admin", true);
  let event = await createTestEvent(s, o1.id);

  console.log(event);
  let res = await s
    .from<Event>("events")
    .insert({
      deleted_at: new Date().toISOString(),
      title: "test event",
      body: "test",
      starts_at: new Date().toISOString(),
      ends_at: new Date(1, 1, 2050).toISOString(),
      organisation_id: o1.id,
    })
    .eq("id", event.id)
    .single();
  expect(res.error).toBeNull();
  expect(res.data);
});

it("does not allow accounts from other organisations to manage events", async () => {
  const { supabase: s1, organisation: o1 } = await getClientUser();
  const { supabase: s2, organisation: o2 } = await getClientUser();

  // roles from different org
  for (let role of ["owner", "admin", "teacher", "teacher_guest", "student"]) {
    const { supabase: s } = await createAccount(s2, o2.id, role, true);
    let res = await createTestEventRaw(s, o1.id);
    expect(res.error).not.toBeNull();
  }
});
