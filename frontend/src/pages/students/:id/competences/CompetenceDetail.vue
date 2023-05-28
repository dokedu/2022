<template>
    <div v-if="competence.entry_account_competences.length > 0">
        <div @click="$emit('toggle-eac', competence)">
            <div class="flex justify-between px-4 py-2 items-center border-b border-b-gray-100">
                <div class="text-gray-500 text-sm">{{ competence.entry_account_competences.length }}
                    {{ competence.entry_account_competences.length > 1 ? 'Einträge' : 'Eintrag' }}
                </div>
                <button type="button" class="hover:bg-gray-200 rounded-md p-0.5">
                    <svg v-if="showEAC" width="28" height="28" viewBox="0 0 28 28" fill="none"
                        xmlns="http://www.w3.org/2000/svg">
                        <g clip-path="url(#clip0_561_57975)">
                            <path d="M18 16L14 12L10 16" stroke="#6B7280" stroke-width="1.5" stroke-linecap="round"
                                stroke-linejoin="round" />
                        </g>
                        <defs>
                            <clipPath id="clip0_561_57975">
                                <rect width="28" height="28" rx="8" fill="white" />
                            </clipPath>
                        </defs>
                    </svg>
                    <svg v-if="!showEAC" width="28" height="28" viewBox="0 0 28 28" fill="none"
                        xmlns="http://www.w3.org/2000/svg">
                        <g clip-path="url(#clip0_561_57824)">
                            <path d="M10 12.0001L14 16.0001L18 12.0001" stroke="#6B7280" stroke-width="1.5"
                                stroke-linecap="round" stroke-linejoin="round" />
                        </g>
                        <defs>
                            <clipPath id="clip0_561_57824">
                                <rect y="7.62939e-05" width="28" height="28" rx="8" fill="white" />
                            </clipPath>
                        </defs>
                    </svg>
                </button>
            </div>
        </div>
        <div v-show="showEAC" class="flex flex-col gap-2 py-1">
            <div v-for="eac in competence.entry_account_competences" class="text-sm text-gray-500 px-4 py-1">
                <span class="font-semibold">Niveau {{ eac.level }}</span> wurde am <span class="font-semibold">{{
                    parseDate(eac.created_at) }}</span> von
                <span class="font-semibold">
                    {{ fullName(eac.entries.account) }}
                </span>
                als
                <router-link :to="{ name: 'entry', params: { id: eac.entry_id } }"
                    class="font-semibold py-0.5 px-1 rounded-lg hover:bg-gray-200">Eintrag</router-link>
                dokumentiert.
            </div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { parseDate } from '../../../../helper/parseDate';

defineProps({
    competence: Object,
    showEAC: Boolean
});

function fullName(account) {
    return `${account.first_name} ${account.last_name}`
}
</script>
