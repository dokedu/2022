const PageLabels = () => import('../pages/labels/index.vue')

export default [
    {
        path: '/labels',
        name: 'labels',
        meta: {
            layout: 'Default',
            // action: { name: 'Label erstellen', to: { name: 'report_new' }, 'data-cy': 'new-report' },
            breadcrumbs: [
                {
                    name: 'Label',
                },
            ],
        },
        component: PageLabels,
    },
]
