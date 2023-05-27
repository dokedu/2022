<template>
    <div>
        <div class="rounded-lg shadow border border-slate-50 bg-white">
            <div v-for="competence in competences" :key="competence.id" class="flex flex-col">
                <router-link v-if="competence.competence_type === 'group'"
                    :to="{ name: 'student-competence', params: { competenceId: competence.id } }"
                    class="px-4 py-2 hover:bg-slate-50 transition-all duration-75 flex justify-between items-center">
                    <span>{{ competence.name }}</span>
                    <svg class="stroke-slate-500" width="20" height="20" viewBox="0 0 20 20" fill="none"
                        xmlns="http://www.w3.org/2000/svg">
                        <path d="M7.5 15L12.5 10L7.5 5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                    </svg>
                </router-link>
                <div v-else class="flex flex-col hover:bg-slate-50 transition-all duration-75 ">
                    <div class="px-4 py-2 flex justify-between items-center border-b border-b-slate-100"
                        @click="toggleEAC(competence)">
                        <span>{{ competence.name }}</span>
                        <div
                            class="rounded-xl bg-slate-50 border border-slate-200 select-none hover:bg-slate-100 hover:border-slate-300 text-blue-700 font-medium w-8 min-w-[32px] p-1 flex justify-center items-center">
                            {{ competence.entry_account_competences.length > 0 ?
                                sortEntryAccountCompetenceByCreatedAt(competence.entry_account_competences)[0].level : 0 }}
                        </div>
                    </div>
                    <div v-if="competence.entry_account_competences.length > 0">
                        <div @click="toggleEAC(competence)">
                            <div class="flex justify-between px-4 py-2 items-center border-b border-b-slate-100">
                                <div class="text-slate-500 text-sm">{{ competence.entry_account_competences.length }}
                                    Einträge
                                </div>
                                <button type="button" class="hover:bg-slate-200 rounded-md">
                                    <svg v-if="showEAC(competence)" width="28" height="28" viewBox="0 0 28 28" fill="none"
                                        xmlns="http://www.w3.org/2000/svg">
                                        <g clip-path="url(#clip0_561_57975)">
                                            <path d="M18 16L14 12L10 16" stroke="#6B7280" stroke-width="1.5"
                                                stroke-linecap="round" stroke-linejoin="round" />
                                        </g>
                                        <defs>
                                            <clipPath id="clip0_561_57975">
                                                <rect width="28" height="28" rx="8" fill="white" />
                                            </clipPath>
                                        </defs>
                                    </svg>
                                    <svg v-if="!showEAC(competence)" width="28" height="28" viewBox="0 0 28 28" fill="none"
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
                        <div v-show="showEAC(competence)" class="flex flex-col gap-2 py-1">
                            <div v-for="eac in competence.entry_account_competences"
                                class="text-sm text-slate-500 px-4 py-1">
                                <span class="font-semibold">Niveau {{ eac.level }}</span> wurde am <span
                                    class="font-semibold">
                                    {{ parseDate(eac.created_at) }}</span> von
                                <span class="font-semibold">
                                    {{ fullName(eac.entries.account) }}
                                </span>
                                als
                                <router-link :to="{ name: 'entry', params: { id: eac.entry_id } }"
                                    class="font-semibold py-0.5 px-1 rounded-lg hover:bg-slate-200">
                                    Eintrag</router-link> dokumentiert.
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div v-if="competences.length < 1">
                Leider sind keine Kompetenzen vorhanden.
            </div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import supabase from "../../../../api/supabase";
import { getOrganisationId } from "../../../../helper/general"
import { parseDate } from "../../../../helper/parseDate"
import { onMounted, ref, watch } from "vue";

const route = useRoute()

const competences = ref([])

const showEACs = ref([])

function toggleEAC(competence) {
    if (showEACs.value.includes(competence.id)) {
        showEACs.value.splice(showEACs.value.indexOf(competence.id), 1)
    } else {
        showEACs.value.push(competence.id)
    }
}

function showEAC(competence) {
    return showEACs.value.includes(competence.id)
}

function fullName(account) {
    return `${account.first_name} ${account.last_name}`
}

function pluckEntriesForCompetence(competence) {
    return competence.entry_account_competences.map(entryAccountCompetence => entryAccountCompetence.entries).flat()
}

function sortEntryAccountCompetenceByCreatedAt(entryAccountCompetences) {
    return entryAccountCompetences.sort((a, b) => {
        if (a.created_at < b.created_at) return 1
        if (a.created_at > b.created_at) return -1
        return 0
    })
}

function fetchCompetences() {
    return supabase
        .from('competences')
        .select('*, entry_account_competences(*, entries(*, account:account_id(*)))')
        .eq("organisation_id", getOrganisationId())
        .eq("competence_id", route.params.competenceId)
        .eq("entry_account_competences.account_id", route.params.id)
        .neq("competence_type", "subject");
}

async function updateCompetences() {
    const { data, error } = await fetchCompetences()
    if (error) return console.error(error)
    // sort data by competence_type and name
    competences.value = data.sort((a, b) => {
        if (a.competence_type < b.competence_type) return 1
        if (a.competence_type > b.competence_type) return -1
        if (a.name > b.name) return 1
        if (a.name < b.name) return -1
        return 0
    })
}


watch(() => route.params.competenceId, async () => {
    await updateCompetences()
})
onMounted(async () => {
    await updateCompetences()
})


</script>