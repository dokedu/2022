<template>
  <div v-if="eac?.competence" class="d-entry-account-competence rounded-lg border-2 border-gray-100 p-2">
    <div class="mb-2 flex justify-between">
      <div>{{ eac.competence.name }}</div>
      <div class="flex items-center">
        <DCompetenceLevel :level="eac.level" :editable="editable" class="mr-2"
          @click="$emit('level', { eac, level: eac.level + 1 })" />
        <div v-if="eac?.competence?.grades" class="min-w-[max-content] rounded-lg bg-blue-100 px-1 text-sm text-blue-900">
          {{ Math.min(...eac.competence.grades) }} - {{ Math.max(...eac.competence.grades) }}
        </div>
        <div v-if="editable" class="ml-2 cursor-pointer rounded-lg hover:bg-gray-100" @click="$emit('remove', eac)">
          <IconX />
        </div>
      </div>
    </div>
    <div v-if="parents && [...parents].reverse().slice(0, -1)" class="flex flex-wrap text-sm text-gray-700">
      <div v-for="competence in [...parents].reverse().slice(0, -1)" :key="competence.id" class="mb-1 mr-1 flex">
        <div class="m-0 rounded-lg bg-gray-100 px-2 py-1 text-sm">{{ competence?.name }}</div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import supabase from '../api/supabase'
import { useSWRVS } from '../api/helper'
import { Competence, EntryAccountCompetence } from '../../../backend/test/types/index'
import { PropType, toRefs } from 'vue'
import DCompetenceLevel from '../components/DCompetenceLevel.vue'
import IconX from '../components/icons/IconX.vue'

export default {
  components: { DCompetenceLevel, IconX },
  props: {
    eac: {
      type: Object as PropType<EntryAccountCompetence>,
      required: true,
    },
    editable: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['remove', 'level'],
  setup(props: { eac: { competence: { id: string; name: string; grades: number[] }; level: number } }) {
    const { eac } = toRefs(props)

    const fetchParents = (id: string) => {
      if (!id) return []

      return supabase.rpc('get_competence_tree', { _competence_id: id })
    }

    const competenceId = eac.value.competence?.id
    const { data: parents } = useSWRVS<{ data: Competence[] }>(
      `/competences/${competenceId}/parents`,
      fetchParents(competenceId),
    )

    return {
      parents,
    }
  },
}
</script>
