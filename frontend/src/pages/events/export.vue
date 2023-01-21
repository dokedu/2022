<template>
  <div class="pb-12">
    <div class="flex items-center justify-between print:hidden">
      <div class="mt-2 flex gap-2">
        <input
          v-model="filter.starts_at"
          type="date"
          class="block rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
        />
        <input
          v-model="filter.ends_at"
          type="date"
          class="block rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
        />
        <label for="deleted"></label>

        <SwitchGroup as="div" class="flex items-center">
          <Switch
            v-model="filter.deleted"
            :class="[
              filter.deleted ? 'bg-blue-600' : 'bg-slate-200',
              'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2',
            ]"
          >
            <span
              aria-hidden="true"
              :class="[
                filter.deleted ? 'translate-x-5' : 'translate-x-0',
                'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
              ]"
            />
          </Switch>
          <SwitchLabel as="span" class="ml-3">
            <span class="text-sm font-medium text-slate-900">Zeige archivierte </span>
          </SwitchLabel>
        </SwitchGroup>
      </div>

      <d-button look="primary" @click="print"> Drucken </d-button>
    </div>

    <div v-if="data?.data === undefined && !data?.error" class="my-4">Lädt...</div>

    <div
      class="mt-4 overflow-hidden shadow ring-1 ring-black ring-opacity-5 print:shadow-none print:ring-opacity-0 md:rounded-lg print:md:rounded-none"
    >
      <table class="min-w-full divide-y divide-slate-300">
        <thead class="bg-slate-50">
          <tr class="divide-x divide-slate-200">
            <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-slate-900">Name</th>
            <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-slate-900">Beschreibung</th>
            <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-slate-900">Von</th>
            <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-slate-900">Bis</th>
            <th scope="col" class="px-2 py-3.5 text-left text-sm font-semibold text-slate-900">Kompetenzen</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-200 bg-white">
          <tr v-for="event in data.data" :key="event.id" class="break-after-column divide-x divide-slate-200">
            <td class="p-3 align-top font-medium text-slate-700">{{ event.title }}</td>
            <td class="p-3 align-top text-sm text-slate-500">{{ event.body }}</td>
            <td class="whitespace-nowrap p-3 align-top text-sm text-slate-500">
              {{ parseDateCalendar(event.starts_at) }}
            </td>
            <td class="space whitespace-nowrap p-3 align-top text-sm text-slate-500">
              {{ parseDateCalendar(event.ends_at) }}
            </td>
            <td class="space w-2/5 p-0 align-top">
              <div v-if="event.subjects && event.subjects.length > 0">
                <div
                  v-for="subject in event.subjects.sort((a, b) => a.subject_name.localeCompare(b.subject_name))"
                  :key="subject.subject_id"
                >
                  <table class="min-w-full divide-y divide-slate-200">
                    <thead class="bg-slate-50">
                      <tr class="divide-x divide-slate-200">
                        <th scope="col" class="px-2 py-1.5 text-left text-sm font-medium text-slate-700">
                          <strong>{{ subject.subject_name }}</strong>
                        </th>
                        <th scope="col" class="px-2 py-1.5 text-left text-sm font-medium text-slate-700">Klassen</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-200 bg-white">
                      <tr
                        v-for="competence in subject.competences.sort((a, b) => a.name.localeCompare(b.name))"
                        :key="competence.id"
                        class="divide-x divide-slate-200"
                      >
                        <td class="p-2 align-top text-sm text-slate-500">{{ competence.name }}</td>
                        <td class="w-[50px] whitespace-nowrap p-2 text-center align-top text-sm text-slate-500">
                          {{
                            competence.grades.length > 0
                              ? `${Math.min(...competence.grades)} -
                                                                                    ${Math.max(...competence.grades)}`
                              : '-'
                          }}
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
              <div v-else class="p-2 pt-3 text-sm text-slate-500">Keine Kompetenzen hinterlegt.</div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="data?.data.length > 500" class="my-4 rounded-md bg-blue-50 p-4 print:hidden">
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
import { parseDateCalendar } from '../../helper/parseDate'
import { getOrganisationId } from '../../helper/general'
import { Competence } from '../../../../backend/test/types'
import { mutate } from 'swrv'
import { Switch, SwitchGroup, SwitchLabel } from '@headlessui/vue'
import { InformationCircleIcon } from '@heroicons/vue/solid'
import DButton from '../../components/ui/DButton.vue'

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
