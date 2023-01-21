const PageCompetences = () => import('../pages/competences/index.vue')
const PageCompetence = () => import('../pages/competences/:id/index.vue')

export default [
  {
    path: '/competences',
    name: 'competences',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Kompetenzen',
        },
      ],
    },
    component: PageCompetences,
  },
  {
    path: '/competences/:id',
    name: 'competence',
    meta: {
      layout: 'Default',
    },
    component: PageCompetence,
  },
]
