const client = new MeiliSearch({
    host: 'http://localhost:7700',
    apiKey: 'masterKey',
})

// meilisearch
function resetIndex({ req }) {
    // get organisation_id from query param
    const organisationId = req.query.organisation_id

    const index = client.index('products')
    index.deleteIndex()
    index.createIndex()
    index.addDocuments(organisationId)
}

function search({ req }) {
    const organisationId = req.query.organisation_id
    const query = req.query.query

    const index = client.index(organisationId)
    const response = index.search(query)

    return response
}
