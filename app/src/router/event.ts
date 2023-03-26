const PageEvents = () => import('../pages/events/index.vue')
const PageEventsExport = () => import('../pages/events/export.vue')
const PageEvent = () => import('../pages/events/:id/index.vue')
const PageEventEdit = () => import('../pages/events/:id/edit.vue')
const PageEventNew = () => import('../pages/events/new.vue')

export default [
  {
    path: '/events',
    name: 'events',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Projekte',
        },
      ],
    },
    component: PageEvents,
  },
  {
    path: '/events/export',
    name: 'events_export',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Projekte',
          to: { name: 'events' },
        },
        {
          name: 'Übersicht',
        },
      ],
    },
    component: PageEventsExport,
  },
  {
    path: '/events/:id',
    name: 'event',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Projekte',
          to: { name: 'events' },
        },
        {
          name: ':id',
        },
      ],
    },
    component: PageEvent,
  },
  {
    path: '/events/new',
    name: 'event_new',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Projekte',
          to: { name: 'events' },
        },
        {
          name: 'Neues Projekt',
        },
      ],
    },
    component: PageEventNew,
  },
  {
    path: '/events/:id/edit',
    name: 'event_edit',
    meta: {
      layout: 'Default',
      breadcrumbs: [
        {
          name: 'Projekte',
          to: { name: 'events' },
        },
        {
          name: ':id',
          to: { name: 'event' },
        },
        {
          name: 'Bearbeiten',
        },
      ],
    },
    component: PageEventEdit,
  },
]
