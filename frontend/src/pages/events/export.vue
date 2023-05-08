<template>
  <div class="pb-12">
    <div class="flex items-center justify-between print:hidden">
      <div class="mt-2 flex gap-2">
        <input v-model="filter.starts_at" type="date"
          class="block rounded-md border-neutral-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm" />
        <input v-model="filter.ends_at" type="date"
          class="block rounded-md border-neutral-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm" />
        <label for="deleted"></label>

        <SwitchGroup as="div" class="flex items-center">
          <Switch v-model="filter.deleted" :class="[
            filter.deleted ? 'bg-blue-600' : 'bg-neutral-200',
            'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2',
          ]">
            <span aria-hidden="true" :class="[
              filter.deleted ? 'tranneutral-x-5' : 'tranneutral-x-0',
              'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
            ]" />
          </Switch>
          <SwitchLabel as="span" class="ml-3">
            <span class="text-sm font-medium text-neutral-900">Zeige archivierte </span>
          </SwitchLabel>
        </SwitchGroup>
      </div>

      <d-button look="primary" @click="print"> Drucken </d-button>
    </div>

    <div v-if="data?.data === undefined && !data?.error" class="my-4">Lädt...</div>

    <div v-if="data?.data !== undefined"
      class="mt-4 shadow text-sm ring-1 ring-black ring-opacity-5 print:shadow-none print:ring-opacity-0 md:rounded-lg print:md:rounded-none">
      <table class="min-w-full divide-y divide-neutral-300">
        <thead class="bg-neutral-50">
          <tr class="divide-x divide-neutral-200">
            <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-neutral-900">Name</th>
            <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-neutral-900">Beschreibung</th>
            <th scope="col" class="px-2 py-3.5 text-left text-sm font-semibold text-neutral-900">Kompetenzen</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-200 bg-white">
          <tr v-for="event in data.data" :key="event.id" class="divide-x divide-neutral-200">
            <td class="p-3 align-top font-medium text-neutral-700">
              <div class="mb-2">{{ event.title }}</div>
              <div class="text-xs text-neutral-500">
                <span class="font-medium">{{ new Date(event.starts_at).toLocaleDateString('de-DE', {
                  year: '2-digit',
                  month: '2-digit', day: '2-digit'
                }) }}</span>
                bis <span class="font-medium">{{ new Date(event.ends_at).toLocaleDateString('de-DE', {
                  year: '2-digit',
                  month: '2-digit', day: '2-digit'
                }) }}</span>
              </div>
            </td>
            <td class="p-3 align-top text-sm text-neutral-500">{{ event.body }}</td>
            <td class="space w-3/5 p-0 align-top">
              <div v-if="event.subjects && event.subjects.length > 0">
                <div v-for="subject in event.subjects.sort((a, b) => a.subject_name.localeCompare(b.subject_name))"
                  :key="subject.subject_id" class="">
                  <table class="min-w-full divide-y divide-neutral-200">
                    <thead class="bg-neutral-50">
                      <tr class="divide-x divide-neutral-200">
                        <th scope="col" class="px-2 py-1.5 text-left text-sm font-medium text-neutral-700">
                          <strong>{{ subject.subject_name }}</strong>
                        </th>
                        <th scope="col" class="px-2 py-1.5 text-left text-sm font-medium text-neutral-700">Klassen</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-neutral-200 bg-white">
                      <tr v-for="competence in subject.competences.sort((a, b) => a.name.localeCompare(b.name))"
                        :key="competence.id" class="divide-x divide-neutral-200">
                        <td class="p-2 align-top text-sm text-neutral-500">{{ competence.name }}
                        </td>
                        <td class="w-[50px] whitespace-nowrap p-2 text-center align-top text-sm text-neutral-500">
                          {{ gradeToText(competence.grades) }}
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
              <div v-else class="p-2 pt-3 text-sm text-neutral-500">Keine Kompetenzen hinterlegt.</div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="data?.data.length >= 1000" class="my-4 rounded-md bg-blue-50 p-4">
      <div class="flex">
        <div class="flex-shrink-0">
          <InformationCircleIcon class="h-5 w-5 text-blue-400" aria-hidden="true" />
        </div>
        <div class="ml-3 flex-1 md:flex md:justify-between">
          <p class="text-sm text-blue-700">
            Derzeit zeigen wir maximal 1000 Projekte an. Wenn deine Organisation diese Grenze erreicht, wende dich bitte
            an den <a href="mailto:support@dokedu.org" class="hover:underline">Dokedu Support</a>.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { debouncedWatch } from '@vueuse/core'
import supabase from '../../api/supabase'
import { useSWRVX } from '../../api/helper'
import { getOrganisationId } from '../../helper/general'
import { Competence } from '../../../../backend/test/types'
import { mutate } from 'swrv'
import { Switch, SwitchGroup, SwitchLabel } from '@headlessui/vue'
import { InformationCircleIcon } from '@heroicons/vue/solid'
import DButton from '../../components/ui/DButton.vue'

function gradeToText(grades: number[]): string {
  if (grades.length > 1) {
    return `${Math.min(...grades)} – ${Math.max(...grades)}`
  } else if (grades.length = 1) {
    return grades[0].toString()
  } else {
    return '-'
  }
}


const filter = ref({
  starts_at: null,
  ends_at: null,
  deleted: false,
  limit: 1000,
  offset: 0,
  search: '',
})

const exportEvents = async () => {
  return supabase.rpc('export_events', {
    _organisation_id: getOrganisationId(),
    _from: filter.value.starts_at ? new Date(filter.value.starts_at) : new Date('2000-01-01'),
    _to: filter.value.ends_at ? new Date(filter.value.ends_at) : new Date('2050-01-01'),
    _show_archived: filter.value.deleted,
  })
}

interface EventWCompetence {
  id: string
  title: string
  subjects:
  | {
    subject_id: string
    subject_name: string
    competences: Competence & { competence_tree: Competence[] }
  }[]
  | null
}

const print = () => window.print()
const { data } = useSWRVX<{ data: { data: EventWCompetence[]; count: number } }>(`/events/export`, exportEvents)

debouncedWatch(
  [filter],
  async () => {
    await mutate(`/events/export`, await exportEvents().then((res) => res))
  },
  { deep: true, debounce: 1000 },
)
</script>
