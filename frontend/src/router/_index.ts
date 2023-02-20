import { createRouter, createWebHistory, RouteLocation, RouteLocationNormalized, RouterOptions } from 'vue-router'
import login from './login'
import entry from './entry'
import { useStore } from '../store/store'
import student from './student'
import event from './event'
import competence from './competence'
import reports from './reports'
import supabase from '../api/supabase'
import admin from './admin'

const protectRoutes = (routes: any[], roles: string[] = []) => {
  return routes.map((route) => {
    if (!route.meta) {
      route.meta = {
        roles: [],
      }
    }

    route.meta.roles = roles
    return route
  })
}

const routes = [
  ...login,
  ...entry,
  ...student,
  ...event,
  ...competence,
  ...reports,
  ...protectRoutes(admin, ['owner', 'admin']),
]

export const router = createRouter(<RouterOptions>{
  history: createWebHistory(),
  routes,
})

interface RouteWithGuard extends RouteLocationNormalized {
  meta: {
    roles?: string[]
  }
}

// TODO: fix because otherwise invite user won't work
//router.beforeResolve((to: RouteWithGuard, from, next) => {
//  if (to.meta?.roles && to.meta?.roles.length > 0) {
//    const store = useStore()
//    if (!to.meta?.roles.includes(store.account.role)) {
//      return next('/')
//    }
//  }
//
//  if (to.hash) {
//    const query = new URLSearchParams(to.hash.substring(1))
//
//    switch (query.get('type')) {
//      case 'reset-password':
//      case 'invite':
//        return next('/reset-password')
//      default:
//        return next()
//    }
//  }
//  return next()
//})

// Prevent user from accessing pages without logging in
export let redirectAfterLogin: RouteLocation = { name: 'entries' } as RouteLocation
router.beforeEach(async (to, from, next) => {
  if (to.name === 'logout') {
    await supabase.auth.signOut()
    useStore().$reset()
    localStorage.clear()
    next({ name: 'login' })
  } else {
    if (to.meta.public === true) {
      next()
    } else {
      if (useStore().user.isLoggedIn) {
        next()
      } else {
        redirectAfterLogin = to
        next('/login')
      }
    }
  }
})
