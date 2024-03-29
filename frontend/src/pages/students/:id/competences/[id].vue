<template>
    <div class="pb-8">
        <div class="px-2 mb-2">
            <h2 v-if="student && student.data" class="text-lg font-semibold mb-2 text-gray-900 px-4">
                {{ `${student?.data?.first_name} ${student?.data?.last_name}` }}
            </h2>
            <input v-model="search" type="text" name="search" id="search" placeholder="Suche"
                class="border-2 border-gray-200 rounded-md w-full focus:ring-0 focus:border-black">
        </div>
        <h2 class="font-medium mb-2 text-gray-900 px-4">
            {{ competence?.data?.name }}
        </h2>
        <div class="rounded-lg shadow border border-gray-50 bg-white">
            <div v-for=" competence  in  filteredCompetences " :key="competence.id" class="flex flex-col">
                <CompetenceEntry :competence="competence" :showEACs="showEACs"
                    @add-account-competence="addAccountCompetence" />
            </div>
            <div v-if="filteredCompetences.length < 1" class="p-4 text-gray-500">
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
import { useStore } from "../../../../store/store";

const route = useRoute()

const showEACs = ref([])
const search = ref("")

async function addAccountCompetence(payload) {
    console.log(payload)

    await supabase
        .from('account_competences')
        .insert({
            student_id: route.params.id,
            account_id: useStore().account.id,
            competence_id: payload.competenceId,
            organisation_id: getOrganisationId(),
            level: payload.level
        })

    await refresh()
}

const filteredCompetences = computed(() => {
    if (search.value === "") return sortCompetencesByCompetenceType(competences.value?.data)
    return sortCompetencesByCompetenceType(competences.value.data.filter(competence => competence.name.toLowerCase().includes(search.value.toLowerCase())))
})

function sortCompetencesByCompetenceType(competences) {
    if (!competences) return []
    // group before competence
    return competences.sort((a, b) => {
        if (a.competence_type === "group" && b.competence_type === "competence") return -1
        if (a.competence_type === "competence" && b.competence_type === "group") return 1
        return 0
    })
}

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

function fetchStudent() {
    return supabase
        .from('accounts')
        .select('*')
        .eq("id", route.params.id)
        .eq("organisation_id", getOrganisationId())
        .single()
}

const { data: competence } = useSWRVX(() => `/competences/${route.params.competenceId}`, fetchCompetence)

const { data: student } = useSWRVX(() => `/competences/${route.params.competenceId}/students`, fetchStudent)

function fetchCompetences() {
    if (route.params.competenceId === undefined) return Promise.resolve({ data: [] })

    return supabase
        .from('competences')
        .select('*, entry_account_competences(*, entries(*, account:account_id(*))), account_competences(*, account:account_id(*))')
        .eq("organisation_id", getOrganisationId())
        .eq("competence_id", route.params.competenceId)
        .is("deleted_at", null)
        .eq("entry_account_competences.account_id", route.params.id)
        .eq("account_competences.student_id", route.params.id)
        .neq("competence_type", "subject")
}

const { data: competences, mutate: refresh } = useSWRVX(() => `/students/${route.params.id}/competences/${route.params.competenceId}`, fetchCompetences)

</script>