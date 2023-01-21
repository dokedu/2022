import { createApp } from 'vue'
import './index.css'
import App from './App.vue'
import { router } from './router/_index'
import { createPinia } from 'pinia'
import { createTestUser, getClient } from './api/helper'
import supabase from './api/supabase'
import { tracker } from './replay'
import * as yup from 'yup'
import yupLocaleDE from './locale/yupLocaleDE'
yup.setLocale(yupLocaleDE)
const app = createApp(App)

const clickOutside = {
  beforeMount: (el: any, binding: any) => {
    el.clickOutsideEvent = (event: any) => {
      // here I check that click was outside the el and his children
      if (!(el == event.target || el.contains(event.target))) {
        // and if it did, call method provided in attribute value
        binding.value()
      }
    }
    document.addEventListener('click', el.clickOutsideEvent)
  },
  unmounted: (el: any) => {
    document.removeEventListener('click', el.clickOutsideEvent)
  },
}

app.use(router)
app.use(createPinia())
app.directive('click-outside', clickOutside)
app.mount('#app')

// OpenReplay Tracker
if (import.meta.env.PROD) tracker.start()

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
window.helper = {}
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
window.helper.createTestUser = createTestUser
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
window.helper.getClient = getClient
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
window.helper.supabase = supabase
