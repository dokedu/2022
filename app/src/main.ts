import { createApp } from 'vue'
import './index.css'
import App from './App.vue'
import { router } from './router/_index'

import { createPinia } from 'pinia'
import pluginPiniaPersist from 'pinia-plugin-persistedstate'

import { createTestUser, getClient } from './api/helper'
import supabase from './api/supabase'
import * as yup from 'yup'
import yupLocaleDE from './locale/yupLocaleDE'
yup.setLocale(yupLocaleDE)


const app = createApp(App)

const pinia = createPinia()
pinia.use(pluginPiniaPersist)

app.use(pinia)
app.use(router)

app.mount('#app')

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
window.helper = {} as any
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
window.helper.createTestUser = createTestUser
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
window.helper.getClient = getClient
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
window.helper.supabase = supabase
