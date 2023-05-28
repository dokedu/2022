<template>
    <div class="flex flex-col hover:bg-gray-50 transition-all duration-75 ">
        <div class="px-4 py-2 flex justify-between items-center border-b border-b-gray-100" @click="toggleEAC(competence)">
            <span>{{ competence.name }}</span>
            <div class="flex gap-2 items-center">
                <div @click.stop="">
                    <DCompetenceLevel :level="competence.entry_account_competences.length > 0 ?
                        sortEntryAccountCompetenceByCreatedAt(competence.entry_account_competences)[0].level : 0"
                        :editable="true" />
                </div>
                <div v-if="false" class="hover:bg-gray-100 rounded-md p-2 flex items-center justify-center" @click.stop="">
                    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path
                            d="M8.00008 8.66668C8.36827 8.66668 8.66675 8.3682 8.66675 8.00001C8.66675 7.63182 8.36827 7.33334 8.00008 7.33334C7.63189 7.33334 7.33341 7.63182 7.33341 8.00001C7.33341 8.3682 7.63189 8.66668 8.00008 8.66668Z"
                            fill="#6B7280" />
                        <path
                            d="M12.6667 8.66668C13.0349 8.66668 13.3334 8.3682 13.3334 8.00001C13.3334 7.63182 13.0349 7.33334 12.6667 7.33334C12.2986 7.33334 12.0001 7.63182 12.0001 8.00001C12.0001 8.3682 12.2986 8.66668 12.6667 8.66668Z"
                            fill="#6B7280" />
                        <path
                            d="M3.33341 8.66668C3.7016 8.66668 4.00008 8.3682 4.00008 8.00001C4.00008 7.63182 3.7016 7.33334 3.33341 7.33334C2.96522 7.33334 2.66675 7.63182 2.66675 8.00001C2.66675 8.3682 2.96522 8.66668 3.33341 8.66668Z"
                            fill="#6B7280" />
                        <path
                            d="M8.00008 8.66668C8.36827 8.66668 8.66675 8.3682 8.66675 8.00001C8.66675 7.63182 8.36827 7.33334 8.00008 7.33334C7.63189 7.33334 7.33341 7.63182 7.33341 8.00001C7.33341 8.3682 7.63189 8.66668 8.00008 8.66668Z"
                            stroke="#6B7280" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
                        <path
                            d="M12.6667 8.66668C13.0349 8.66668 13.3334 8.3682 13.3334 8.00001C13.3334 7.63182 13.0349 7.33334 12.6667 7.33334C12.2986 7.33334 12.0001 7.63182 12.0001 8.00001C12.0001 8.3682 12.2986 8.66668 12.6667 8.66668Z"
                            stroke="#6B7280" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
                        <path
                            d="M3.33341 8.66668C3.7016 8.66668 4.00008 8.3682 4.00008 8.00001C4.00008 7.63182 3.7016 7.33334 3.33341 7.33334C2.96522 7.33334 2.66675 7.63182 2.66675 8.00001C2.66675 8.3682 2.96522 8.66668 3.33341 8.66668Z"
                            stroke="#6B7280" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
                    </svg>
                </div>
                <router-link v-if="competence.competence_type === 'group'"
                    :to="{ name: 'student-competence', params: { competenceId: competence.id } }"
                    class="p-1.5 rounded-md hover:bg-gray-100 transition-all duration-75 flex justify-between items-center">
                    <svg class="stroke-gray-500" width="20" height="20" viewBox="0 0 20 20" fill="none"
                        xmlns="http://www.w3.org/2000/svg">
                        <path d="M7.5 15L12.5 10L7.5 5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                    </svg>
                </router-link>
            </div>
        </div>
        <CompetenceDetail :competence="competence" @toggle-eac="toggleEAC" :showEAC="showEAC(competence)" />
    </div>
</template>

<script lang="ts" setup>
import { defineProps } from 'vue';
import CompetenceDetail from './CompetenceDetail.vue';
import DCompetenceLevel from '../../../../components/DCompetenceLevel.vue';

const props = defineProps({
    competence: Object,
    showEACs: Array
});

function toggleEAC(competence) {
    if (props.showEACs.includes(competence.id)) {
        props.showEACs.splice(props.showEACs.indexOf(competence.id), 1)
    } else {
        props.showEACs.push(competence.id)
    }
}

function showEAC(competence) {
    return props.showEACs?.includes(competence.id)
}

function sortEntryAccountCompetenceByCreatedAt(entryAccountCompetences) {
    return entryAccountCompetences.sort((a, b) => {
        if (a.created_at < b.created_at) return 1
        if (a.created_at > b.created_at) return -1
        return 0
    })
}
</script>
