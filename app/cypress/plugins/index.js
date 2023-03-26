const path = require('path')
const { startDevServer } = require('@cypress/vite-dev-server')
const { Client } = require('pg')
const { Seeds } = require('../../../seeds/seeds.ts')
const {SeedMachine} = require("../support/seedMachine.ts");

module.exports = (on, config) => {
  on('dev-server:start', (options) => {
    return startDevServer({
      options,
      viteConfig: {
        configFile: path.resolve(__dirname, '../../vite.config.ts'),
      },
    })
  })

  const client = new Client({
    host: process.env.POSTGRES_HOST || "localhost",
    user: 'postgres',
    password: '12341234'
  })
  client.connect()
  const seeds = new Seeds(client)


  on('task', {
    ...SeedMachine(client, seeds),
  })

  return config
}
