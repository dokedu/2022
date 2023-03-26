<template>
  <div v-if="event" class="mt-4">
    <div class="flex items-center justify-between">
      <DInput v-model="event.title" name="title" placeholder="Name vom Event" type="text"
        class="border-1 rounded-lg border-slate-300" />
      <DButton look="primary" @click="save">Speichern</DButton>
    </div>
    <DTextarea v-model="event.body" name="body" placeholder="Beschreibe das Event"
      class="border-1 mt-4 w-full rounded-lg border-slate-300" rows="10"></DTextarea>
    <div class="mt-4 flex space-x-2 text-sm text-slate-500">
      <div>
        <DInput id="starts_at" v-model="event.starts_at" name="starts_at" type="datetime-local" label="Startet am"
          class="border-1 w-full rounded-lg border-slate-300" />
      </div>
      <div>
        <DInput id="ends_at" v-model="event.ends_at" name="ends_at" label="Endet am" type="datetime-local"
          class="border-1 w-full rounded-lg border-slate-300" />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import supabase from '../../../api/supabase'
import { useSWRVS } from '../../../api/helper'
import { useRoute, useRouter } from 'vue-router'
import DButton from '../../../components/DButton.vue'
import { getOrganisationId } from '../../../utils/general'
import DInput from '../../../components/DInput.vue'
import * as yup from 'yup'
import { useForm } from 'vee-validate'
import DTextarea from '../../../components/DTextarea.vue'
import { computed } from 'vue'

const route = useRoute()
const router = useRouter()

const fetchEvent = () =>
  supabase.from('events').select('*').eq('organisation_id', getOrganisationId()).eq('id', route.params.id).single()

const { data: eventData } = useSWRVS<any>(`/events/${route.params.id}`, fetchEvent())

const event = computed({
  get: () => {
    const _event = eventData.value
    if (!_event) return null

    // ToDo: fix timezone problems?
    // _event.starts_at = `${starts_at.toISOString().slice(0, 11)}${starts_at.toTimeString().slice(0, 8)}`
    // _event.ends_at = `${ends_at.toISOString().slice(0, 11)}${ends_at.toTimeString().slice(0, 8)}`

    if (_event?.starts_at) {
      _event.starts_at = `${_event?.starts_at.slice(0, 16)}`
    }
    if (_event?.ends_at) {
      _event.ends_at = `${_event?.ends_at.slice(0, 16)}`
    }

    return _event
  },

  set: (value) => {
    eventData.value = value
  },
})

const schema = yup.object({
  body: yup.string().min(1).required().label('Beschreibung'),
  title: yup.string().min(1).required().label('Titel'),
  starts_at: yup
    .date()
    .nullable()
    .required()
    .label('Startet am')
    .typeError('Endet am ist ein Pflichtfeld')
    .max(
      yup.ref('ends_at', {
        map: (value) => {
          return isFinite(value) && value ? value : new Date('9999-01-01')
        },
      }),
      'Startet am muss früher sein als Endet am',
    ),
  ends_at: yup
    .date()
    .min(
      yup.ref('starts_at', {
        map: (value) => {
          return isFinite(value) && value ? value : new Date('0000-01-01')
        },
      }),
      'Endet am muss später sein als Startet am',
    )
    .nullable()
    .required()
    .typeError('Endet am ist ein Pflichtfeld')
    .label('Endet am'),
})

const { validate } = useForm({ validationSchema: schema })

const save = async () => {
  const { valid } = await validate()
  if (!valid) return

  if (event.value === undefined || event.value.id === undefined) {
    alert('Konnte nicht gespeichert werden. Bitte den Support kontaktieren unter help@dokedu.org.')
    return
  }

  await supabase
    .from('events')
    .update(event.value as unknown as Event)
    .eq('id', event.value.id)

  await router.push({ name: 'event', params: { id: event.value.id } })
}
</script>
