import {createApp} from 'vue'
import './style.css'
import App from './App.vue'
import urql, {cacheExchange, fetchExchange} from '@urql/vue';

const app = createApp(App)

app.use(urql, {
    url: 'http://localhost:8080/query',
    exchanges: [cacheExchange, fetchExchange],
})

app.mount('#app')
