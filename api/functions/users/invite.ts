export function InviteUser(mods: modules.Modules) {
    return async (c: echo.Context) => {
        const ctx = c as helper.ApiContext;

        const req = await ctx.bind<InviteUserRequest>();

        // validate request
        if (!ctx.validate(req)) {
            return ctx.badRequest();
        }

        // check if user is admin or owner in the organisation
        const cnt = await ctx.tx.newSelect()
            .from("accounts as a")
            .innerJoin("identities as i").on("i.id = a.identity_id")
            .where("i.user_id = ?", ctx.claims.sub)
            .where("a.organisation_id = ?", req.organisationID)
            .where("a.role = 'admin' or role = 'owner'")
            .where("a.deleted_at IS NULL")
            .where("i.deleted_at IS NULL")
            .count(ctx.request().context);

        if (cnt !== 1) {
            return ctx.forbidden();
        }

        // check if user already exists
        let user = await ctx.tx.newSelect()
            .from("auth.users")
            .column("id", "email")
            .where("email = ?", req.email)
            .fetchOne<models.User>(ctx.request().context);

        if (user === undefined) {
            user = await mods.supabase.inviteUserByEmail(req.email);
        }

        // check if the user has an identity already
        let identity = await ctx.tx.newSelect()
            .from("identities")
            .where("user_id = ?", user.id)
            .where("deleted_at IS NULL")
            .fetchOne<models.Identity>(ctx.request().context);
        if (identity === undefined) {
            // create identity
            identity = {
                userID: user.id,
                globalRole: "default",
            };

            await ctx.tx.newInsert()
                .into("identities")
                .values(identity)
                .execute(ctx.request().context);
        }

        // check if account already exists
        const cnt = await ctx.tx.newSelect()
            .from("accounts")
            .where("identity_id = ?", identity.id)
            .where("organisation_id = ?", req.organisationID)
            .where("deleted_at IS NULL")
            .count(ctx.request().context);

        if (cnt !== 0) {
            return ctx.conflict("user already part of organisation");
        }

        // create account
        const account = {
            identityID: {
                string: identity.id,
                valid: true,
            },
            organisationID: req.organisationID,
            role: req.role,
            firstName: req.firstName,
            lastName: req.lastName,
        };

        await ctx.tx.newInsert()
            .into("accounts")
            .values(account)
            .execute(ctx.request().context);

        return ctx.ok();
    };
}