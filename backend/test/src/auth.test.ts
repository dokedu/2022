import {
  getClient,
  getClientUser,
  mailhogGetMessages,
  mailhogReset,
} from "./helper";
import { Organisation } from "../types";
import axios from "axios";

test("should be able to login", async () => {
  const supabase = await getClient();

  let email = Math.random() + "test@example.com";
  let res = await supabase.auth.signUp({
    email: email,
    password: "12345678",
  });
  expect(res.error).toBeNull();

  res = await supabase.auth.signIn({
    email: email,
    password: "12345678",
  });
  expect(res.error).toBeNull();

  res = await supabase.auth.signIn({
    email: "does@not.exist",
    password: "12345678",
  });
  expect(res.error.message).toEqual("Invalid login credentials");
});

test("should be able to register and initialize account", async () => {
  const supabase = await getClient();

  let r = await supabase.auth.signUp({
    email: "User" + Math.random() + "@example.com",
    password: "12345678",
  });
  expect(r.error).toBeNull();

  // user should not have an organisation
  let org = await supabase.from("organisations").select();
  expect(org.error).toBeNull();
  expect(org.data).toHaveLength(0);

  let rInit = await supabase.initAccount();
  expect(rInit.error).toBeNull();

  // user cannot init twice
  rInit = await supabase.initAccount();
  expect(rInit.error).not.toBeNull();
});

test("cannot get info about other organisations", async () => {
  const { supabase: s1 } = await getClientUser();
  const { supabase: s2 } = await getClientUser();

  let res = await s1.from<Organisation>("organisations").select();
  expect(res.error).toBeNull();
  expect(res.data).toHaveLength(1);

  let res2 = await s2.from<Organisation>("organisations").select();
  expect(res.error).toBeNull();
  expect(res.data).toHaveLength(1);

  expect(res.data[0].id).not.toEqual(res2.data[0].id);
});

test("should be able to reset password", async () => {
  await mailhogReset();
  const { supabase: s1, user: u1 } = await getClientUser();

  // get new supabase
  let supabase = await getClient();
  await supabase.auth.api.resetPasswordForEmail(u1.email);

  const msgs = await mailhogGetMessages();
  expect(msgs.total).toEqual(1);
  expect(msgs.items[0].To).toHaveLength(1);
  expect(msgs.items[0].To[0].Mailbox).toEqual(u1.email.split("@")[0]);
  expect(msgs.items[0].Content.Body).toContain("Reset password");

  const regex = /.*verify\?token=(.*?)&amp;/gs;
  expect(msgs.items[0].Content.Body).toMatch(regex);
  const regexRes = regex.exec(msgs.items[0].Content.Body);
  expect(regexRes).toHaveLength(2);
  const token = regexRes[1].substring(2).replace(/[\r\n=]/g, "");

  // later on (in production) the url is going to contain all required things. in testing, manually construct it (also strip away 3D from token).
  const url = `${
    process.env.SUPABASE_URL || "http://localhost:8000"
  }/auth/v1/verify?token=${token}&type=recovery&redirect_to=http://localhost:3001`;

  //send to kong
  const res = await axios.get(url, {
    maxRedirects: 0,
    validateStatus: (a) => a === 303,
  });
  const accessRegex = /a href=".*?access_token=(.*?)&amp;/gs;
  const resetAccessTokenRes = accessRegex.exec(res.data);
  expect(resetAccessTokenRes).toHaveLength(2);
  const resetAccessToken = resetAccessTokenRes[1];

  // finally, invoke supabase
  await supabase.auth.api.updateUser(resetAccessToken, {
    password: "secure,yes!",
  });

  // get yet another supabase client (to prevent cross talking, token leak, which wouldn't occur in web)
  supabase = await getClient();

  // check if we can no longer login with the old password
  const signInRes = await supabase.auth.signIn({
    email: u1.email,
    password: "12345789",
  });
  expect(signInRes.error).not.toBeNull();

  // login with the new password should work
  const { user } = await supabase.auth.signIn({
    email: u1.email,
    password: "secure,yes!",
  });
  expect(user.email).toEqual(u1.email);
});
