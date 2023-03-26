import { createClient } from '@supabase/supabase-js'
import { nanoid } from 'nanoid'
import axios from 'axios'

// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
// Cypress.Commands.add('login', (email, password) => { ... })
//
//
// -- This is a child command --
// Cypress.Commands.add('drag', { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add('dismiss', { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite('visit', (originalFn, url, options) => { ... })

function getClient() {
  return createClient(
    Cypress.env('SUPABASE_URL') || 'http://localhost:3001', 'JWT')
}

Cypress.Commands.add('init_user', () => {
  const client = getClient()
  const email = `test.${nanoid()}@dokedu.email`

  cy.then(() =>
    client.auth.signUp({
      email,
      password: '12345678',
    }),
  ).then((res) => {
    expect(res.error).to.be.null

    cy.then(() => initAccount(client)).then((initRes) => {
      expect(initRes.error).to.be.null
      // get the identity
      cy.then(() => client.from('identities').select().eq('id', initRes.data.identity_id).single()).then((identity) => {
        expect(identity.error).to.be.null

        // get the account
        cy.then(() => client.from('accounts').select().eq('id', initRes.data.account_id).single()).then((account) => {
          expect(account.error).to.be.null

          cy.wrap({ supabase: client, user: res.user, identity: identity.data, account: account.data })
        })
      })
    })
  })
})

async function initAccount(supabase) {
  try {
    return {
      error: null,
      data: (
        await axios.post(
          `${supabase.supabaseUrl}/backend/auth/init_account`,
          {},
          {
            headers: {
              'Content-Type': 'application/json',
              Accept: 'application/json',
              apikey: supabase.supabaseKey,
              Authorization: `Bearer ${supabase.auth.currentSession?.access_token}`,
            },
          },
        )
      ).data,
    }
  } catch (e) {
    return { error: e, supabase }
  }
}
