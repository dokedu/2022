const PageStudents = () => import('../pages/students/index.vue')
const PageStudent = () => import('../pages/students/:id/index.vue')

export default [
  {
    path: '/students',
    name: 'students',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Schüler',
        },
      ],
    },
    component: PageStudents,
  },
  {
    path: '/students/:id',
    name: 'student',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Schüler',
          to: { name: 'students' },
        },
        {
          name: ':id',
        },
      ],
    },
    component: PageStudent,
  },
]
