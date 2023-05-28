<template>
    <div class="pb-8">
        <div class="px-2 mb-2">
            <input v-model="search" type="text" name="search" id="search" placeholder="Suche"
                class="border-2 border-gray-200 rounded-md w-full focus:ring-0 focus:border-black">
        </div>
        <h2 class="text-lg font-semibold mb-2 text-gray-900 px-4">{{ competence?.data?.name }}</h2>
        <div class="rounded-lg shadow border border-gray-50 bg-white">
            <div v-for="competence in filterCompetences?.data" :key="competence.id" class="flex flex-col">
                <CompetenceEntry :competence="competence" :showEACs="showEACs" />
            </div>
            <div v-if="filterCompetences?.data.length < 1" class="p-4 text-gray-500">
                Hier gibt es keine weiteren Kompetenzen. Probiere es mit einer anderen Gruppe.
            </div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import supabase from "../../../../api/supabase";
import { getOrganisationId } from "../../../../helper/general"
import { computed, ref } from "vue";
import CompetenceEntry from "./CompetenceEntry.vue";
import { useSWRVX } from "../../../../api/helper";

const route = useRoute()

const showEACs = ref([])
const search = ref("")

const filterCompetences = computed(() => {
    if (search.value === "") return competences.value
    return {
        data: competences.value.data.filter(competence => competence.name.toLowerCase().includes(search.value.toLowerCase()))
    }
})

function fetchCompetence() {
    if (route.params.competenceId === undefined) return Promise.resolve({ data: null })

    return supabase
        .from('competences')
        .select('*')
        .eq("id", route.params.competenceId)
        .eq("organisation_id", getOrganisationId())
        .is("deleted_at", null)
        .single()
}

const { data: competence } = useSWRVX(() => `/competences/${route.params.competenceId}`, fetchCompetence)

function fetchCompetences() {
    if (route.params.competenceId === undefined) return Promise.resolve({ data: [] })

    return supabase
        .from('competences')
        .select('*, entry_account_competences(*, entries(*, account:account_id(*)))')
        .eq("organisation_id", getOrganisationId())
        .eq("competence_id", route.params.competenceId)
        .is("deleted_at", null)
        .eq("entry_account_competences.account_id", route.params.id)
        .neq("competence_type", "subject")
}

const { data: competences } = useSWRVX(() => `/students/${route.params.id}/competences/${route.params.competenceId}`, fetchCompetences)

</script>