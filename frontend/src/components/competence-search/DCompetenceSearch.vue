<template>
  <div
    v-if="open"
    class="fixed inset-0 z-10 overflow-y-auto"
    aria-labelledby="modal-title"
    role="dialog"
    aria-modal="true"
  >
    <div class="flex min-h-screen items-end justify-center px-4 pt-4 pb-20 text-center sm:block sm:p-0">
      <div
        class="fixed inset-0 bg-slate-500 bg-opacity-75 transition-opacity"
        aria-hidden="true"
        @click="$emit('close')"
      ></div>

      <span class="hidden sm:inline-block sm:h-screen sm:align-middle" aria-hidden="true">&#8203;</span>

      <div
        id="d-competence-search"
        class="inline-block transform overflow-hidden rounded-lg bg-white px-4 pt-5 pb-4 text-left align-bottom shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-4xl sm:p-6 sm:align-top"
      >
        <div class="grid grid-cols-9 gap-4">
          <div class="left col-span-5">
            <div class="search-header mb-4">
              <div class="search mb-2">
                <input
                  v-model="search"
                  type="text"
                  class="w-full rounded-lg border-slate-300"
                  placeholder="Suche nach Fächern, Gruppen oder Kompetenzen"
                />
              </div>
              <div v-show="filters.length > 0" class="filters flex items-baseline">
                <div class="label mr-2 text-xs uppercase text-slate-700">Filter</div>
                <div class="items flex items-baseline">
                  <div
                    v-for="filter in filters"
                    :key="`filter_${filter.id}`"
                    class="mr-2 cursor-pointer rounded-lg bg-slate-50 px-1 text-sm filter focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-1"
                    tabindex="0"
                    @click="removeFilter"
                    @keydown.enter="removeFilter"
                  >
                    {{ filter.name }}
                  </div>
                </div>
              </div>
            </div>
            <div class="results">
              <div v-show="subjects?.data?.length > 0" class="subjects mb-4">
                <div class="label mb-2 text-sm uppercase text-slate-500">Fächer</div>
                <div class="items divide-y divide-slate-200">
                  <div v-for="subject in subjects?.data" :key="subject.id">
                    <div
                      class="my-1 cursor-pointer rounded-lg px-2 py-1 hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                      tabindex="0"
                      @click="addFilter(subject)"
                      @keydown.enter="addFilter(subject)"
                    >
                      {{ subject.name }}
                    </div>
                  </div>
                  <div>
                    <div
                      class="my-1 cursor-pointer rounded-lg p-2 text-sm text-slate-500 hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                      tabindex="0"
                    >
                      <span class="font-medium">{{ subjects?.count - 3 }}</span> weitere Fächer
                    </div>
                  </div>
                </div>
              </div>
              <div v-show="groups?.data?.length > 0" class="groups mb-4">
                <div class="label mb-2 text-sm uppercase text-slate-500">Themen</div>
                <div class="items divide-y divide-slate-200">
                  <div v-for="group in groups?.data" :key="group.id">
                    <div
                      class="cursor-pointer rounded-lg hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                      tabindex="0"
                      @click="addFilter(group)"
                      @keydown.enter="addFilter(group)"
                    >
                      <DCompetence :competence="group" @click="addFilter(group)" @keydown.enter="addFilter(filter)" />
                    </div>
                  </div>
                  <div>
                    <div
                      class="my-1 cursor-pointer rounded-lg p-2 text-sm text-slate-500 hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                      tabindex="0"
                    >
                      <span class="font-medium">{{ groups?.count - 3 }}</span> weitere Themen
                    </div>
                  </div>
                </div>
              </div>
              <div v-show="competences?.data?.length > 0" class="competences mb-4">
                <div class="label mb-2 text-sm uppercase text-slate-500">Kompetenzen</div>
                <div class="items divide-y divide-slate-200">
                  <div v-for="competence in competences?.data" :key="competence.id">
                    <div
                      class="cursor-pointer rounded-lg hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                      tabindex="0"
                      @click="addCompetence(competence)"
                      @keydown.enter="addCompetence(competence)"
                    >
                      <DCompetence :competence="competence" />
                    </div>
                  </div>
                  <div>
                    <div
                      class="my-1 cursor-pointer rounded-lg p-2 text-sm text-slate-500 hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                      tabindex="0"
                    >
                      <span class="font-medium">{{ competences?.count - 3 }}</span> weitere Kompetenzen
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="right col-span-4 flex flex-col justify-between">
            <div>
              <div class="label">Ausgewählte Kompetenzen</div>
              <div class="competences">
                <DCompetence v-for="competence in selected" :key="competence.id" :competence="competence" />
              </div>
            </div>
            <div class="actions flex w-full justify-end">
              <DButton look="primary" @click="emitCompetences">Add competences</DButton>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { useSWRVX } from '../../api/helper'
import { Competence } from '../../../../backend/test/types/index'
import DCompetence from '../DCompetence.vue'
import { useCompetenceSearchStore } from '../../store/competenceSearch'
import { onMounted, onUnmounted, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { mutate } from 'swrv'
import DButton from '../ui/DButton.vue'

export default {
  name: 'DCompetenceSearch',
  components: { DCompetence, DButton },
  props: {
    open: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['close', 'input'],
  setup(_: never, context: { emit: (arg0: string) => void }) {
    const store = useCompetenceSearchStore()

    const close = () => {
      context.emit('close')
    }

    const handleKeydown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        // Pressing the ESC key closes the modal.
        close()
      }
    }
    onMounted(() => {
      window.addEventListener('keydown', handleKeydown)
    })

    onUnmounted(() => {
      window.removeEventListener('keydown', handleKeydown)
    })

    const { search, selected, filters, refetch } = storeToRefs(store)

    const { data: subjects } = useSWRVX<{ data: Competence[] }>(`/search/subjects`, store.getCompetences('subject', 3))
    const { data: groups } = useSWRVX<{ data: Competence[] }>(`/search/groups`, store.getCompetences('group', 3))
    const { data: competences } = useSWRVX<{ data: Competence[] }>(
      `/search/competences`,
      store.getCompetences('competence', 3),
    )

    watch(refetch, () => {
      mutate(
        '/search/subjects',
        store.getCompetences('subject', 3).then((res) => res.data as any),
      )
      mutate(
        '/search/groups',
        store.getCompetences('group', 3).then((res) => res.data as any),
      )
      mutate(
        '/search/competences',
        store.getCompetences('competence', 3).then((res) => res.data as any),
      )
      store.refetch = false
    })

    watch(search, (search, oldSearch) => {
      if (search !== oldSearch) {
        mutate(
          '/search/subjects',
          store.getCompetences('subject', 3).then((res) => res.data as any),
        )
        mutate(
          '/search/groups',
          store.getCompetences('group', 3).then((res) => res.data as any),
        )
        mutate(
          '/search/competences',
          store.getCompetences('competence', 3).then((res) => res.data as any),
        )
      }
    })

    const emitCompetences = () => {
      context.emit('input', selected.value)
      context.emit('close')
    }

    return {
      search,
      subjects,
      groups,
      competences,
      selected,
      filters,
      addFilter: store.addFilter,
      removeFilter: store.removeFilter,
      addCompetence: store.addCompetence,
      emitCompetences,
    }
  },
}
</script>
