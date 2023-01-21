import promisify from 'cypress-promise'

let _account
let _supabase
beforeEach(async () => {
  const { supabase, account } = await promisify(cy.init_user())

  _account = account
  _supabase = supabase
})

it('the nav link should lead to the reports page', () => {
  cy.visit('/')
  cy.get('[href="/reports"]').click()
  cy.url().should('include', '/reports')

  cy.get('[data-cy="breadcrumbs"]').should('contain', 'Berichte')
})

it.only('should show reports', () => {
  cy.task('createReport', [_account.id, _account.organisation_id])

  // give the server some time to create the report
  cy.wait(4000)

  cy.visit('/reports')
  cy.get('[data-cy="reports"]').children().should('have.length', 2)

  // in this seed configuration, both should be done
  cy.get('[data-cy="reports"]').children().should('contain', 'Fertig')
  cy.get('[data-cy="reports"]').children().should('contain', 'Fertig')
})

it('should be able to create a new report', () => {
  cy.task('createReportPrerequisites', [_account.organisation_id])

  cy.visit('/reports')
  cy.get('[data-cy="reports"]').children().should('have.length', 0)

  cy.get('[data-cy="new-report"]').click()
  cy.url().should('include', '/reports/new')

  cy.get('[data-cy="student"]').find('input').type('test student{downarrow}{enter}')
  cy.get('[data-cy="from"]').type('2010-01-01')
  cy.get('[data-cy="to"]').type('2030-01-01')
  cy.get('[data-cy="type"]').select('Einträge')

  cy.get('[data-cy="create"]').click()
  cy.url().should('contain', '/reports')
  cy.url().should('not.contain', '/reports/new')

  //give the server some time to create the report
  // eslint-disable-next-line cypress/no-unnecessary-waiting
  cy.wait(2000)
  cy.reload()

  cy.get('[data-cy="reports"]').children().should('have.length', 1)
  cy.get('[data-cy="reports"]').children().should('contain.text', 'test student')
  cy.get('[data-cy="reports"]').children().should('contain.text', 'Fertig')
})

it('Bug: new report, blank page show after visiting /students', () => {
  cy.task('createReportPrerequisites', [_account.organisation_id])

  cy.visit('/students')
  cy.get('[href="/reports"]').click()
  cy.get('[data-cy="new-report"]').click()
  expect(cy.get('[data-cy="student"]')).exist
})

it('should be able to click on a report, see details, and download the pdf', () => {
  cy.task('createReport', [_account.id, _account.organisation_id])

  // give the server some time to create the report
  // eslint-disable-next-line cypress/no-unnecessary-waiting
  cy.wait(2000)

  cy.visit('/reports')
  cy.get('[data-cy="reports"]').children().should('have.length', 2)

  cy.get('[data-cy="reports"] > :nth-child(1)').click()
  cy.url().should('match', /.+?\/reports\/.{21}/)

  cy.get('[data-cy="name"]').should('contain', 'test student')
  cy.get('[data-cy="teacher"]').should('contain', 'Max Mustermann')
  cy.get('[data-cy="to"]').should('contain', '2050')
  cy.get('[data-cy="from"]').should('contain', '2010')

  // need to do this, since the button would open the pdf in a new tab. This is not possible in cypress
  let response
  cy.intercept('/storage/v1/object/sign/**', (req) => {
    req.continue((res) => {
      response = { ...res }
      res.body = null
      res.statusCode = 500
      return null
    })
  }).as('sign')

  cy.get('[data-cy="viewPDF"]').click()
  cy.wait('@sign').then(() => {
    expect(response.body).to.have.property('signedURL')
  })
})
