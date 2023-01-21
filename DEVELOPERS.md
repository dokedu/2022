# Dokedu Developers

## Setup

* make sure you have a working docker-environment running on your pc.
* `sh ./scripts/start.sh` should get you up and running. please keep in mind, that this scripts stops all other running docker containers on your system.
* if you have to reset the db / import a new schema, you can use `sh ./scripts/reset.sh`. make sure you do that if pull / switch branches.
* there is also `sh ./scripts/testAll.sh`, which tests all things.
* make sure you active the [pre-commit](https://pre-commit.com/) hooks using `pre-commit install` in the project root.

## Frontend

You can find the frontend in the `fronted` folder.

* Run `yarn` to download dependencies
* Run `yarn dev` to start the dev server using vite
* Run `yarn cypress:start` to start cypress for testing

If you need seeds to manually login during development (we prefer test driven development, but sometimes this can be handy) you can use (from the project root) `cd seeds/ && yarn runDevSeed` to load a default user.

## Services

- frontend [app.dokedu.org](https://app.dokedu.org)
- api gateway [api.dokedu.org](https://api.dokedu.org)

## Database

We use Postgres as a database. As we are very much based on RLS, this means that you cannot normally perform many actions, such as a hard-delete. To get around this you can do the following:

## Manual Postgres interaction

- Development auth is `postgres`:`12341234`
- To impersonate a user, use `set local role = 'authenticated'; set local request.jwt.claim.sub = '<User ID Here>';` in a transaction
  - If you want to get out of the user context, use `set local role = 'postgres';` or end the transaction.
- To enable hard delete, use `set local app.hard_delete = 'on';` in a transaction
  - If you want to get out of the hard delete context, use `set local app.hard_delete = 'off';` or end the transaction.
- Make sure to commit / rollback the transaction.