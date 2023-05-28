<template>
    <div>
        <div class="px-2 mb-2">
            <input v-model="search" type="text" name="search" id="search" placeholder="Suche"
                class="border-2 border-gray-200 rounded-md w-full focus:ring-0 focus:border-black">
        </div>
        <div>
            <router-link :to="{ name: 'student-competence', params: { competenceId: competence.id } }"
                v-for="competence in filterCompetences" :key="competence.id"
                class="px-4 py-2 rounded-md hover:bg-gray-100 transition-all duration-75 flex justify-between items-center">
                <span>{{ competence.name }}</span>
                <svg class="stroke-gray-500" width="20" height="20" viewBox="0 0 20 20" fill="none"
                    xmlns="http://www.w3.org/2000/svg">
                    <path d="M7.5 15L12.5 10L7.5 5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                </svg>
            </router-link>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import supabase from "../../../../api/supabase";
import { useSWRVS } from "../../../../api/helper";
import { getOrganisationId } from "../../../../helper/general"
import { computed, ref } from "vue";

const route = useRoute()

const search = ref("")

const fetchCompetences = () =>
    supabase
        .from('competences')
        .select('*')
        .eq("organisation_id", getOrganisationId())
        .is("deleted_at", null)
        .eq("competence_type", "subject")

const { data: competences } = useSWRVS(`/students/${route.params.id}/competences`, fetchCompetences())

const filterCompetences = computed(() => {
    if (search.value === "") return competences.value
    return competences.value.filter(competence => competence.name.toLowerCase().includes(search.value.toLowerCase()))
})

</script>