import * as fs from 'fs'
import {Client} from "pg";

export class Seeds {
    private client: Client

    constructor(client: Client) {
        this.client = client
    }

    getSeed(name: string) {
        let pathS = __filename.split('/')
        pathS.pop()
        pathS.push(name);

        return fs.readFileSync(pathS.join('/')).toString()
    }

    createSampleEntryContent(msg: string) {
        return {
            "type": "doc",
            "content": [
                {
                    "type": "paragraph",
                    "content": [
                        {
                            "text": msg,
                            "type": "text"
                        }
                    ]
                }
            ]
        }
    }

    async runTestSeed(account_id: string) {
        await this.client.query(`insert into entries (date, body, account_id)
                                 values (now(), $1, $2)
                                 returning id;
        `, [this.createSampleEntryContent('this is a test, coming from a seed.'), account_id])
        return null
    }

    async createTestEntries(account_id: string) {
        const res = await this.client.query(`insert into entries (date, body, account_id)
                                 values (now(), $1, $4), (now(), $2, $4), (now(), $3, $4)
                                 returning id;
        `, [
            this.createSampleEntryContent('Test content.'),
            this.createSampleEntryContent('we support emojis. 🥵🔥'),
            this.createSampleEntryContent('中文文本没问题。'),
            account_id])

        return res.rows
    }

    async createTestEntryDeletedCompetence(org_id: string, teacher_id: string) {
        const subjectRes = await this.client.query("insert into competences (name, competence_id, competence_type, organisation_id, grades) VALUES ('deleted subject', null, 'subject', $1, '{1}') returning id", [org_id])
        const subjectId = subjectRes.rows[0].id

        const groupRes = await this.client.query("insert into competences (name, competence_id, competence_type, organisation_id, grades) VALUES ('deleted group', $1, 'group', $2, '{1}') returning id", [subjectId, org_id])
        const groupId = groupRes.rows[0].id

        const competenceRes = await this.client.query("insert into competences (name, competence_id, competence_type, organisation_id, grades) VALUES ('deleted competence', $1, 'competence', $2, '{1}') returning id", [groupId, org_id])
        const competenceId = competenceRes.rows[0].id

        // create test student
        const studentRes = await this.client.query("insert into accounts (role, organisation_id, first_name, last_name) values ('student', $1, 'Test', 'Student') returning id", [org_id])
        const studentId = studentRes.rows[0].id

        // create entry
        const entryRes = await this.client.query("insert into entries (date, body, account_id) values (now(), $1, $2) returning id;", [this.createSampleEntryContent('Test content.'), teacher_id])
        const entryId = entryRes.rows[0].id

        // create entry_accounts
        await this.client.query("insert into entry_accounts (entry_id, account_id) values ($1, $2)", [entryId, studentId])

        // create entry_competences
        await this.client.query("insert into entry_account_competences (level, account_id, entry_id, competence_id) values ($1, $2, $3, $4), ($1, $2, $3, $5), ($1, $2, $3, $6)", [1, studentId, entryId, competenceId, subjectId, groupId])

        // delete subject, group and competence
        await this.client.query("delete from competences where id = $1", [subjectId])
        await this.client.query("delete from competences where id = $1", [groupId])
        await this.client.query("delete from competences where id = $1", [competenceId])

        return true
    }

    async createTestReports(account_id: string) {

    }

    async manualDevTesting() {
        //fill me, if we have demand.
    }

}