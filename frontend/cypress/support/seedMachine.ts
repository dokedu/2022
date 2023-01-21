import { Client } from 'pg'
import { Account } from '../../../backend/test/types/index'

export const SeedMachine = (client: Client, seeds) => {
  const that = {
    async testSeed(data) {
      return seeds.runTestSeed(data.account_id)
    },
    async createTestEntries(account_id) {
      return seeds.createTestEntries(account_id)
    },
    async createTestEntryDeletedCompetence([org_id, teacher_id]) {
      return seeds.createTestEntryDeletedCompetence(org_id, teacher_id)
    },
    async createTestEntryAccount([entry_id, student_id]) {
      await client.query('insert into entry_accounts (entry_id, account_id) VALUES ($1, $2) returning *', [
        entry_id,
        student_id,
      ])
    },
    async createAccount([orgId, role]): Promise<Account> {
      const a = await client.query(
        "insert into accounts (role, organisation_id, first_name, last_name) VALUES ($1, $2, 'test', $1) returning *",
        [role, orgId],
      )

      return a.rows[0]
    },
    async createReport([accountId, orgId]) {
      const { student } = await that.createReportPrerequisites([orgId])

      const r = await client.query(
        "insert into reports (status, type, \"from\", \"to\", account_id, student_account_id) values ('pending', 'report', '2010-01-01', '2050-01-01', $1, $2) returning *",
        [accountId, student.id],
      )
      const r2 = await client.query(
        "insert into reports (status, type, \"from\", \"to\", account_id, student_account_id) values ('pending', 'subjects', '2010-01-01', '2050-01-01', $1, $2) returning *",
        [accountId, student.id],
      )
      return [r.rows[0], r2.rows[0]]
    },
    async createReportPrerequisites([orgId]) {
      const student = await that.createAccount([orgId, 'student'])
      const entries = await that.createTestEntries(student.id)
      await that.createTestEntryAccount([entries[0].id, student.id])
      await that.createTestEntryAccount([entries[1].id, student.id])
      await that.createTestEntryAccount([entries[2].id, student.id])

      return { student }
    },
  }

  return that
}
