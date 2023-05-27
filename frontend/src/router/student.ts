const PageStudents = () => import('../pages/students/index.vue')
const PageStudent = () => import('../pages/students/:id/index.vue')
const PageStudentCompetences = () => import('../pages/students/:id/competences/index.vue')
const PageStudentCompetence = () => import('../pages/students/:id/competences/[id].vue')

export default [
  {
    path: '/students',
    name: 'students',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Schülerübersicht',
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
          name: 'Schülerübersicht',
          to: { name: 'students' },
        },
        {
          name: 'Schüler',
        },
      ],
    },
    component: PageStudent,
  },
  {
    path: '/students/:id/competences',
    name: 'student-competences',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Schülerübersicht',
          to: { name: 'students' },
        },
        {
          name: 'Schüler',
          to: { name: 'student' },
        },
        {
          name: 'Fächer',
        },
      ],
    },
    component: PageStudentCompetences,
  },
  {
    path: '/students/:id/competences/:competenceId',
    name: 'student-competence',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Schülerübersicht',
          to: { name: 'students' },
        },
        {
          name: 'Schüler',
          to: { name: 'student' },
        },
        {
          name: 'Fächer',
          to: { name: 'student-competences' },
        },
        {
          name: 'Kompetenzen',
        },
      ],
    },
    component: PageStudentCompetence,
  },
]
