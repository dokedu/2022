<template>
  <div class="d-competence my-1 rounded-lg px-2 py-1">
    <div class="mb-1 text-xs uppercase text-slate-500">{{ i18nCompetenceType(competence.competence_type) }}</div>
    <div class="mb-1 flex items-start justify-between gap-2">
      <div>{{ competence.name }}</div>
      <div class="flex items-start">
        <div v-if="competence.grades" class="min-w-[max-content] rounded-lg bg-blue-100 px-1 text-sm text-blue-900">
          {{ Math.min(...competence.grades) }} - {{ Math.max(...competence?.grades) }}
        </div>
        <div v-if="removable"
          class="ml-1 cursor-pointer rounded-lg hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
          tabindex="0" @click="$emit('remove', competence)" @keyup.enter="$emit('remove', competence)">
          <IconX />
        </div>
      </div>
    </div>
    <div v-if="competence.parents" class="flex flex-wrap text-sm text-slate-700">
      <div v-for="parent in [...competence.parents].reverse()" :key="parent.id" class="mb-1 mr-1 flex">
        <div class="m-0 rounded-lg bg-slate-100 px-2 py-1 text-xs hover:bg-slate-200">{{ parent.name }}</div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { PropType } from 'vue'
import { Competence } from '../../../backend/test/types/index'
import IconX from './icons/IconX.vue'

export default {
  components: {
    IconX,
  },
  props: {
    competence: {
      type: Object as PropType<Competence>,
      required: true,
    },
    removable: {
      type: Boolean as PropType<boolean>,
      default: false,
    },
  },
  emits: ['remove'],
  setup() {
    const i18nCompetenceType = (field: string) => ({
      'competence': 'Kompetenz',
      'subject': 'Fach',
      'group': 'Thema',
    }[field])

    return {
      i18nCompetenceType
    }
  }
}
</script>
