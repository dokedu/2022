import Login from '../pages/login/index.vue'
import PasswordForgot from '../pages/login/forgot-password.vue'
import PasswordReset from '../pages/login/reset-password.vue'

const Workspaces = () => import('../pages/login/workspaces.vue')

export default [
  {
    path: '/login',
    name: 'login',
    meta: {
      layout: 'Login',
      public: true,
    },
    component: Login,
  },
  {
    path: '/logout',
    name: 'logout',
    meta: {
      layout: 'Login',
      public: true,
    },
    component: Login,
  },
  {
    path: '/login/workspaces',
    name: 'workspaces',
    meta: {
      layout: 'Login',
    },
    component: Workspaces,
  },
  {
    path: '/forgot-password',
    name: 'forgot-password',
    meta: {
      layout: 'Login',
      public: true,
    },
    component: PasswordForgot,
  },
  {
    path: '/reset-password',
    name: 'password-reset',
    meta: {
      layout: 'Login',
      public: true,
    },
    component: PasswordReset,
  },
]
