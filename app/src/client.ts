import {Client, cacheExchange, fetchExchange} from '@urql/vue';

export default new Client({
    url: 'http://localhost:8080/graphql',
    exchanges: [cacheExchange, fetchExchange],
});
