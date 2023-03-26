const PageStudents = () => import('../pages/students/index.vue')
const PageStudent = () => import('../pages/students/:id/index.vue')
const PageStudentEntries = () => import('../pages/students/:id/entries.vue')

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
  {
    path: '/students/:id/entries',
    name: 'student_entries',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Schüler',
          to: { name: 'students' },
        },
        {
          name: ':id',
          to: { name: 'student' },
        },
        {
          name: 'Einträge',
        },
      ],
    },
    component: PageStudentEntries,
  },
]
