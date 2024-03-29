export default [
    {
        path: '/settings/profile',
        name: 'settings-profile',
        meta: {
            layout: 'Default',
            breadcrumbs: [
                {
                    name: 'Settings',
                },
            ],
        },
        component: () => import('../pages/settings/profile.vue'),
    }
]
