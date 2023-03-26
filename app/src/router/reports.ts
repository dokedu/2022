const PageReports = () =>  import('../pages/reports/index.vue')
const PageReport = () =>  import('../pages/reports/:id/index.vue')
const PageReportNew = () =>  import('../pages/reports/new/index.vue')

export default [
  {
    path: '/reports',
    name: 'reports',
    meta: {
      layout: 'Default',
      action: { name: 'Bericht erstellen', to: { name: 'report_new' }, 'data-cy': 'new-report' },
      breadcrumbs: [
        {
          name: 'Berichte',
        },
      ],
    },
    component: PageReports,
  },
  {
    path: '/reports/new',
    name: 'report_new',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Berichte',
          to: { name: 'reports' },
        },
        {
          name: 'Neu',
        },
      ],
    },
    component: PageReportNew,
  },
  {
    path: '/reports/:id',
    name: 'report',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Berichte',
          to: { name: 'reports' },
        },
        {
          name: ':id',
        },
      ],
    },
    component: PageReport,
  },
]
