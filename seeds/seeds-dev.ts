import { Client } from "pg";
import { Seeds } from "./seeds";
import { createClient } from "@supabase/supabase-js";
import ApiClient from "../backend/test/types/ApiClient";

(async () => {
  const client = new Client({
    host: process.env.POSTGRES_HOST || "localhost",
    user: "postgres",
    password: "12341234",
  });
  await client.connect();

  const supabase = new ApiClient(
    createClient(
      "http://localhost:8000", "jwt" // TODO: add dev jwt
    )
  );

  try {
    const count = await client.query(`select *
                                               from auth.users
                                               where email = 'dev@dokedu.org'`);
    if (count.rowCount !== 0) {
      console.error(
        "user dev@dokedu.org already exists. reset the db before using this seed."
      );
    }

    const { user, error } = await supabase.auth.signUp({
      email: "dev@dokedu.org",
      password: "12345678",
    });

    if (error) {
      console.error(error.message);
      throw Error(error.message);
    }

    const res = await supabase.initAccount();
    if (res.error) {
      console.error(res.error.message);
      throw Error(res.error.message);
    }

    const seeds = new Seeds(client);
    await seeds.manualDevTesting();

    console.log(
      "user dev@dokedu.org:12345678 was created. (don't forget to write tests after manual testing :D)"
    );
  } finally {
    await client.end();
  }
})();
