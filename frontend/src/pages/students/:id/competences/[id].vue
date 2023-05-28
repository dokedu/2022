<template>
    <div class="pb-8">
        <div class="rounded-lg shadow border border-gray-50 bg-white">
            <div v-for="competence in competences" :key="competence.id" class="flex flex-col">
                <CompetenceEntry :competence="competence" :showEACs="showEACs" />
            </div>
            <div v-if="competences.length < 1" class="p-4 text-gray-500">
                Hier gibt es keine weiteren Kompetenzen. Probiere es mit einer anderen Gruppe.
            </div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import supabase from "../../../../api/supabase";
import { getOrganisationId } from "../../../../helper/general"
import { onMounted, ref, watch } from "vue";
import CompetenceEntry from "./CompetenceEntry.vue";

const route = useRoute()

const competences = ref([])

const showEACs = ref([])

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
    if (error) return
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