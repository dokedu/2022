<template>
  <div v-if="event" class="mt-4">
    <div class="mb-8">
      <img v-show="image?.signedUrl" :src="image?.signedUrl" alt="" class="h-48 w-full rounded-lg object-cover" />
      <div v-show="!image" class="flex h-48 w-full items-center justify-center rounded-lg bg-slate-100 object-cover">
        <DIcon name="image" />
      </div>
    </div>
    <div class="mb-4 flex items-center justify-between">
      <div class="break-words text-2xl">{{ event.title }}</div>
      <div class="flex space-x-2">
        <DButton look="danger-light" @click="handleDeleteEvent">
          <DIcon name="trash" color="red" size="20" />
        </DButton>
        <DButton look="secondary" :to="{ name: 'event_edit' }">Bearbeiten</DButton>
      </div>
    </div>
    <div class="text-slate-700">{{ event.body }}</div>
    <div class="mt-4 flex space-x-2 text-sm text-slate-500">
      <div>{{ parseDate(event.starts_at) }}</div>
      <div>-</div>
      <div>{{ parseDate(event.ends_at) }}</div>
    </div>

    <div v-if="competences.length === 0 && isValidating" class="mt-6 p-2 border rounded-lg">
      <div>Lädt gerade</div>
    </div>

    <div v-else class="mt-6 p-2 border rounded-lg">
      <div class="flex flex-col gap-2 divide-y">
        <DCompetence v-for="c in competences" :competence="c" removable @remove="deleteEventCompetence(c.id)" />
      </div>
      <DButton look="secondary" class="w-full mt-3" size="28" @click="isSearchOpen = true">Kompetenz hinzufügen
      </DButton>
    </div>

    <DErrorModal v-if="isDeleteModalVisible" title="Event archivieren" @accept="deleteEvent"
      @cancel="isDeleteModalVisible = false">
      Bist du sicher, dass du das Event "{{ event.title }}" archivieren möchtest?
    </DErrorModal>

    <DCompetenceSearch v-if="isSearchOpen" @close="isSearchOpen = false" @add="addCompetences" />
  </div>
</template>

<script lang="ts" setup>
import supabase from '../../../api/supabase'
import { useSWRVS } from '../../../api/helper'
import { useRoute, useRouter } from 'vue-router'
import { parseDate } from '../../../utils/parseDate'
import DButton from '../../../components/DButton.vue'
import { getOrganisationId } from '../../../utils/general'
import DIcon from '../../../components/DIcon.vue'
import DErrorModal from '../../../components/DErrorModal.vue'
import DCompetenceSearch from '../../../components/d-competence-search/DCompetenceSearch.vue'
import { Competence, Event } from '../../../../../backend/test/types/index'
import { ref, computed, watch, onMounted } from 'vue'
import DCompetence from '../../../components/DCompetence.vue'

const isSearchOpen = ref(false)

const route = useRoute()
const router = useRouter()

const isDeleteModalVisible = ref(false)

const fetchEvent = () => {
  return supabase
    .from('events')
    .select('*')
    .eq('organisation_id', getOrganisationId())
    .eq('id', route.params.id)
    .single()
}

const { data: event } = useSWRVS<Event>(`/events/${route.params.id}`, fetchEvent())

// Instead of deleting the event immediately, we first display a confirmation modal
const handleDeleteEvent = () => isDeleteModalVisible.value = true

const deleteEvent = async () => {
  await supabase.from('events').update({ deleted_at: new Date().toISOString() }).eq('id', event?.value?.id)

  isDeleteModalVisible.value = false

  await router.push({ name: 'events' })
}

// image

const fetchEventImage = (event: undefined | Event) => {
  if (!event) return false
  if (!event.image_file_bucket_id) return false
  if (!event.image_file_name) return false

  return supabase.storage.from(event.image_file_bucket_id).createSignedUrl(event.image_file_name, 60)
}

const swrvsImageKey = () => event?.value?.image_file_bucket_id && `/events/${event?.value?.id}/image`

const { data: image } = useSWRVS<{ signedUrl: string } | undefined>(swrvsImageKey, fetchEventImage(event?.value))

// event competences

const fetchEventCompetences = () =>
  supabase
    .from('event_competences')
    .select('*, competence:competence_id!inner (*)')
    .eq('event_id', route.params.id)


const eventCompetencesKey = computed(() => `/events/${route.params.id}/competences`)

const { data: eventCompetences, mutate, isValidating } = useSWRVS(eventCompetencesKey.value, fetchEventCompetences())

const deleteEventCompetence = async (competenceId: string) => {
  await supabase.from('event_competences').update({ deleted_at: new Date().toISOString() }).eq('competence_id', competenceId).eq('event_id', route.params.id)

  mutate(() => fetchEventCompetences().then((res) => res.data))
}

onMounted(() => {
  mutate(() => fetchEventCompetences().then((res) => res.data))
})

const addCompetences = async (competences: Competence[]) => {
  if (event === undefined) return

  const ids = eventCompetences.value.map((el: any) => ({ competence_id: el.competence_id, id: el.id }))
  let values = []

  for (const competence of competences) {
    const id = ids.find((el: any) => el.competence_id === competence.id)?.id
    values.push(
      {
        id,
        event_id: event?.value.id,
        competence_id: competence.id,
        deleted_at: null,
      },
    )
  }

  await supabase.from('event_competences').upsert(values)

  mutate(() => fetchEventCompetences().then((res) => res.data))
}

const filteredEventCompetences = computed(() => {
  if (eventCompetences === undefined || eventCompetences.value === undefined) return []
  return eventCompetences.value.filter((el: any) => el.deleted_at === null)
})

const competences = ref<Competence[]>([])

// reload the competence tree
watch(filteredEventCompetences, async (newValue: any) => {
  if (!newValue) return

  competences.value = await Promise.all(
    newValue.map(async (c) => {
      const { data: parents } = await supabase.rpc('get_competence_tree', { _competence_id: c.competence_id })
      return {
        ...c.competence,
        parents: parents?.slice(1),
      }
    }) as Promise<Competence>[],
  )
})

</script>
