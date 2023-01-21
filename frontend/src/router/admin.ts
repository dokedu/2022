const AdminPage = () => import('../pages/admin/index.vue')
const AdminUsersPage = () => import('../pages/admin/users.vue')
const AdminStudentsPage = () => import('../pages/admin/students.vue')
const AdminBillingPage = () => import('../pages/admin/billing.vue')

export default [
  {
    path: '/admin',
    name: 'admin',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Admin',
        },
      ],
    },
    redirect: { name: 'admin_users' },
    component: AdminPage,
    children: [
      {
        path: 'users',
        name: 'admin_users',
        component: AdminUsersPage,
      },
      {
        path: 'students',
        name: 'admin_students',
        component: AdminStudentsPage,
      },
      {
        path: 'students',
        name: 'admin_billing',
        component: AdminBillingPage,
      },
    ],
  },
]
