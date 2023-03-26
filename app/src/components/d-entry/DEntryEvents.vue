<template>
  <div>
    <div v-show="entryEvents?.length > 0" class="mt-8">
      <div class="flex items-center justify-between">
        <div class="mb-1 select-none text-xl font-semibold text-slate-700">Events</div>
      </div>
      <div>
        <div v-if="entryEvents" class="flex flex-col divide-y">
          <div v-for="event in entryEvents" :key="event.id" class="my-1 flex items-center justify-between pt-2">
            <div class="">{{ event.event.first_name }} {{ event.event.title }}</div>
            <div class="cursor-pointer rounded-lg hover:bg-slate-100" @click="store.removeEvent(event)">
              <IconX />
            </div>
          </div>
        </div>
      </div>
    </div>

    <DModal :open="open" @close="open = false">
      <div class="flex min-h-[450px] flex-col justify-between">
        <div>
          <div class="mb-1">
            <div class="mb-4 text-gray-700">Projekte</div>
            <input v-model="search" type="text" class="w-full rounded-lg border-slate-300"
              placeholder="Projekt suchen" />
            <div class="mt-1 flex flex-wrap">
              <div v-for="event in entryEvents" :key="event.id" class="m-1 ml-0 flex rounded-lg border p-1 text-sm">
                {{ event.event.title }}
                <span class="ml-1 cursor-pointer rounded-lg hover:bg-slate-100">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="2 0 20 20" fill="none"
                    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                    class="feather feather-x stroke-slate-500">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                  </svg>
                </span>
              </div>
            </div>
          </div>
          <div class="mb-2 flex flex-col space-y-1">
            <div v-for="event in events?.data" :key="event.id" class="cursor-pointer rounded-lg p-1 hover:bg-slate-100"
              @click="store.addEvent(event)">
              {{ event.title }}
            </div>
            <div v-show="events?.count === 0" class="p-1">Keine Ergebnisse</div>
          </div>
        </div>
        <DPagination v-show="events?.count > 0" :limit="a.limit" :count="events?.count" :offset="a.offset"
          @change="setOffset" />
      </div>
    </DModal>
  </div>
</template>
<script lang="ts" setup>
import supabase from '../../api/supabase'
import { useSWRVX } from '../../api/helper'
import DModal from '../DModal.vue'
import { useEntryStore } from '../../store/entry'
import DPagination, { paginationProps } from '../DPagination.vue'
import { computed, ref, watch } from 'vue'
import { mutate } from 'swrv'
import { storeToRefs } from 'pinia'
import DButton from '../DButton.vue'
import IconX from '../icons/IconX.vue'
import { getOrganisationId } from '../../utils/general'

const store = useEntryStore()

const open = computed({
  get: () => store.openModal === 'events',
  set: (value) => (value ? (store.openModal = 'events') : (store.openModal = '')),
})

const a = ref(paginationProps)
a.value.limit = 10

const search = ref('')

const { events: entryEvents } = storeToRefs(store)

const eventsQuery = computed(() =>
  supabase
    .from('events')
    .select('*', { count: 'exact' })
    .is('deleted_at', null)
    .eq('organisation_id', getOrganisationId())
    .or(`title.ilike.%${search.value}%`)
    .range(a.value.offset, a.value.offset + a.value.limit - 1),
)

const fetchEvents = async () => {
  return eventsQuery.value.then((res) => res)
}

const { data: events } = useSWRVX<any>(`/entries/new/events`, fetchEvents)

watch(search, (value, old) => {
  mutate(`/entries/new/events`, fetchEvents())
})

const setOffset = (val: number) => {
  if (val < 0) return
  if (val > events?.value?.count) return

  a.value.offset = val

  mutate(`/entries/new/events`, fetchEvents())
}
</script>
