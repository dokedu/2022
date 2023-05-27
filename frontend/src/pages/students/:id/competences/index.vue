<template>
    <div>
        <div>
            <router-link :to="{ name: 'student-competence', params: { competenceId: competence.id } }"
                v-for="competence in competences" :key="competence.id"
                class="px-4 py-2 rounded-md hover:bg-slate-100 transition-all duration-75 flex justify-between items-center">
                <span>{{ competence.name }}</span>
                <svg class="stroke-slate-500" width="20" height="20" viewBox="0 0 20 20" fill="none"
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

const route = useRoute()

const fetchCompetences = () =>
    supabase
        .from('competences')
        .select('*')
        .eq("organisation_id", getOrganisationId())
        .eq("competence_type", "subject")

const { data: competences } = useSWRVS(`/students/${route.params.id}/competences`, fetchCompetences())


</script>