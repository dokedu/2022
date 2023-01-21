const PageEntries = () => import('../pages/entries/index.vue')
const PageEntry = () => import('../pages/entries/:id/index.vue')
const PageEntryEdit = () => import('../pages/entries/:id/edit.vue')
const PageEntryNew = () => import('../pages/entries/new/index.vue')

export default [
  {
    path: '/entries',
    alias: '/',
    name: 'entries',
    meta: {
      layout: 'Default',
      action: { name: 'Eintrag erstellen', to: { name: 'entry_new' } },
      breadcrumbs: [
        {
          name: 'Einträge',
        },
      ],
    },
    component: PageEntries,
  },
  {
    path: '/entries/new',
    name: 'entry_new',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Einträge',
          to: { name: 'entries' },
        },
        {
          name: 'Neuer Eintrag',
        },
      ],
    },
    component: PageEntryNew,
  },
  {
    path: '/entries/:id',
    name: 'entry',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Einträge',
          to: { name: 'entries' },
        },
        {
          name: ':id',
        },
      ],
    },
    component: PageEntry,
  },
  {
    path: '/entries/:id/edit',
    name: 'entry_edit',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Einträge',
          to: { name: 'entries' },
        },
        {
          name: ':id',
          to: { name: 'entry', params: { id: ':id' } },
        },
        {
          name: 'Eintrag bearbeiten',
        },
      ],
    },
    component: PageEntryEdit,
  },
]
