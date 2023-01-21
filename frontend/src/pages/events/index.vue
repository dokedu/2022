<template>
  <div class="mt-4 flex space-x-2">
    <input v-model="filter.search" type="text" class="w-full rounded-lg border-slate-300"
      placeholder="Projekt suchen" />
    <DButton look="secondary" :to="{ name: 'events_export' }">Exportieren</DButton>
    <DButton look="primary" :to="{ name: 'event_new' }">Neues Projekt</DButton>
  </div>

  <pre>{{ isValidating }}</pre>

  <div class="mt-2 flex gap-2">
    <select v-model="filter.limit" name="limit" id="limit" class="rounded-lg border border-slate-300 px-3 py-1 pr-8">
      <option v-for="i in [5, 20, 50, 100, 200]" :value="i">{{ i }}</option>
    </select>
    <select class="rounded-lg border border-slate-300 px-3 py-1 pr-8">
      <option value="week" selected>Woche</option>
      <option value="month" disabled>Monat</option>
    </select>
    <input v-model="filter.starts_at" type="date" class="rounded-lg border border-slate-300 px-2 py-1" />
    <input v-model="filter.ends_at" type="date" class="rounded-lg border border-slate-300 px-2 py-1" />
    <label for="deleted"></label>

    <SwitchGroup as="div" class="flex items-center">
      <Switch v-model="filter.deleted" :class="[
        filter.deleted ? 'bg-blue-600' : 'bg-gray-200',
        'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2',
      ]">
        <span aria-hidden="true" :class="[
          filter.deleted ? 'translate-x-5' : 'translate-x-0',
          'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
        ]" />
      </Switch>
      <SwitchLabel as="span" class="ml-3">
        <span class="text-sm font-medium text-gray-900">Zeige archivierte </span>
      </SwitchLabel>
    </SwitchGroup>
  </div>

  <div v-for="year in eventsGroupedYearWeek" class="mt-5 select-none">
    <div class="mb-3 text-xl">{{ year.year }}</div>

    <div v-for="week in year.weeks" class="mb-6">
      <div class="my-2 flex items-center space-x-2">
        <div class="text-sm text-slate-600">
          {{ parseDateCalendarShort(getFirstDate(year.year, week.week)) }} -
          {{ parseDateCalendarShort(getLastDate(year.year, week.week)) }}
        </div>

        <div v-if="parseInt(week.week) === getWeek(new Date())" class="flex space-x-2 text-sm text-slate-400">
          (aktuelle Woche)
        </div>
      </div>

      <div class="flex flex-col">
        <div v-for="(event, index) in week.events" class="border-b" :class="{ 'border-t': index === 0 }">
          <router-link class="my-1 grid grid-cols-5 items-center gap-1 rounded-md px-2 py-1 hover:bg-slate-50"
            :class="[isPast(event) ? 'text-slate-500' : '']" :to="{ name: 'event', params: { id: event.id } }">
            <div class="col-span-3 w-full" :class="{ 'line-through': event.deleted_at !== null }">
              {{ event.title }}
            </div>
            <div class="w-full text-right">
              {{ parseDateCalendar(event.starts_at) }}
            </div>
            <div class="w-full text-right">
              {{ parseDateCalendar(event.ends_at) }}
            </div>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>
<script lang="ts" setup>
import DButton from '../../components/ui/DButton.vue'
import { computed, onMounted, ref, watch } from 'vue'
import supabase from '../../api/supabase'
import { useSWRVX } from '../../api/helper'
import { mutate } from 'swrv'
import { parseDateCalendarShort, parseDateCalendar } from '../../helper/parseDate'
import { getOrganisationId } from '../../helper/general'
import { useRoute, useRouter } from 'vue-router'
import { Switch, SwitchGroup, SwitchLabel } from '@headlessui/vue'

const filter = ref({
  starts_at: null,
  ends_at: null,
  deleted: false,
  limit: 50,
  offset: 0,
  search: '',
})

const route = useRoute()
const router = useRouter()

onMounted(() => {
  if (!route.query) return

  for (const key in route.query) {
    if (key === 'deleted') {
      filter.value.deleted = route.query[key] === 'true'
    } else {
      filter.value[key] = route.query[key]
    }
  }
})

const eventsQuery = computed(() => {
  let fetcher = supabase
    .from('events')
    .select('*', { count: 'exact' })
    .eq('organisation_id', getOrganisationId())
    .order('starts_at')
    .limit(50)
    .range(filter.value.offset, filter.value.offset + filter.value.limit - 1)

  if (filter.value.search) {
    fetcher = fetcher.or(`title.ilike.%${filter.value.search}%,body.ilike.%${filter.value.search}%`)
  }

  // deleted
  if (!filter.value.deleted) {
    fetcher = fetcher.is('deleted_at', null)
  }

  if (filter.value.starts_at) {
    let date = new Date(filter.value.starts_at)
    fetcher = fetcher.gte('starts_at', date.toISOString())
  }

  if (filter.value.ends_at) {
    let date = new Date(filter.value.ends_at)
    date.setDate(date.getDate() + 1)
    fetcher = fetcher.lte('ends_at', date.toISOString())
  }

  return fetcher
})

const fetchEvents = async () => {
  return eventsQuery.value.then((res) => res)
}

const { data: events } = useSWRVX<{ data: Event[]; count: number }>(`/events`, fetchEvents)

watch(
  [filter],
  async (s) => {
    filter.value.offset = 0

    await router.push({
      name: 'events',
      query: { ...filter.value },
    })

    await mutate(`/events`, await fetchEvents().then((res) => res))
  },
  { deep: true },
)

const isPast = (event: Event) => {
  return new Date(event.ends_at) < new Date()
}

const getWeek = (date: Date) => {
  var date = new Date(date.getTime())
  date.setHours(0, 0, 0, 0)
  // Thursday in current week decides the year.
  date.setDate(date.getDate() + 3 - ((date.getDay() + 6) % 7))
  // January 4 is always in week 1.
  var week1 = new Date(date.getFullYear(), 0, 4)
  // Adjust to Thursday in week 1 and count number of weeks from date to week1.
  return 1 + Math.round(((date.getTime() - week1.getTime()) / 86400000 - 3 + ((week1.getDay() + 6) % 7)) / 7)
}

// Group events by year and then week
const eventsGroupedYearWeek = computed(() => {
  const e = events?.value?.data || []
  const grouped = e.reduce((acc, event) => {
    const year = new Date(event.starts_at).getFullYear()
    const week = getWeek(new Date(event.starts_at))
    if (!acc[year]) {
      acc[year] = {}
    }
    if (!acc[year][week]) {
      acc[year][week] = []
    }
    acc[year][week].push(event)
    return acc
  }, {} as { [key: number]: { [key: number]: Event[] } })

  return Object.keys(grouped).map((key) => ({
    year: key,
    weeks: Object.keys(grouped[key]).map((week) => ({
      week: week,
      events: grouped[key][week],
    })),
  }))
})

// get first date by year and week number
const getFirstDate = (year: number, week: number) => {
  const date = new Date(year, 0, 3)
  date.setDate(date.getDate() + (week - 1) * 7)
  return date
}

// get last date by year and week number
const getLastDate = (year: number, week: number) => {
  const date = new Date(year, 0, 3)
  date.setDate(date.getDate() + (week - 1) * 7 + 6)
  return date
}
</script>
