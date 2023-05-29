<template>
    <div class="flex flex-col hover:bg-gray-50 transition-all duration-75 ">
        <div class="px-4 py-2 flex justify-between items-center border-b border-b-gray-100" @click="toggleEAC(competence)">
            <span>{{ competence.name }}</span>
            <div class="flex gap-2 items-center">
                <div @click.stop="openModal">
                    <DCompetenceLevel :level="eacs.length > 0 ?
                        eacs[0].level : 0" :editable="true" />
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

        <dialog ref="dialog"
            class="absolute w-96 bg-white backdrop:bg-gray-400 backdrop:bg-opacity-50 rounded-xl shadow-md">
            <p class="mb-2 text-gray-700 font-medium">Welches Niveau möchtest du für "<span
                    class="text-gray-900 font-semibold">
                    {{ competence.name }}
                </span>" manuell hinterlegen?</p>
            <form method="dialog" class="flex flex-col gap-4" @submit="closeDialog">
                <select name="level" id="level" v-model="niveau"
                    class="rounded-md focus:ring-0 border-2 border-gray-100 focus:border-blue-500">
                    <option :value="0">Niveau 0</option>
                    <option :value="1">Niveau 1</option>
                    <option :value="2">Niveau 2</option>
                    <option :value="3">Niveau 3</option>
                </select>
                <div class="flex justify-between gap-4">
                    <button class="px-4 py-1 rounded-md bg-gray-100 hover:bg-gray-200 text-black" value="cancel"
                        formmethod="dialog">Abbrechen</button>
                    <button class="px-4 py-1 rounded-md bg-black hover:bg-gray-800 shadow text-white" type="submit"
                        id="confirmBtn" value="submit">Speichern</button>
                </div>
            </form>
        </dialog>
    </div>
</template>

<script lang="ts" setup>
import { computed, defineProps, onMounted, ref } from 'vue';
import CompetenceDetail from './CompetenceDetail.vue';
import DCompetenceLevel from '../../../../components/DCompetenceLevel.vue';

const props = defineProps({
    competence: Object,
    showEACs: Array
});

const dialog = ref();
const niveau = ref(0);

function openModal() {
    dialog.value.showModal();
}

const emit = defineEmits(['add-account-competence']);

function closeDialog(event) {
    if (event.submitter.value === 'submit') {
        createAccountCompetence(niveau.value);
    }
}

const eacs = computed(() => {
    const _eacs = [...props?.competence?.entry_account_competences, ...props?.competence?.account_competences]

    return sortEntryAccountCompetenceByCreatedAt(_eacs)
})

function toggleEAC(competence) {
    if (props.showEACs.includes(competence.id)) {
        props.showEACs.splice(props.showEACs.indexOf(competence.id), 1)
    } else {
        props.showEACs.push(competence.id)
    }
}

function createAccountCompetence(level: number) {
    emit('add-account-competence', {
        competenceId: props.competence.id,
        level: level
    });
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
