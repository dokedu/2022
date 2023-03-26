<template>
  <div v-if="event" class="mt-4">
    <div class="flex items-center justify-between">
      <DInput v-model="event.title" name="title" type="text" placeholder="Name vom Event"
        class="border-1 rounded-lg border-slate-300" />
      <DButton look="primary" @click="save">Speichern</DButton>
    </div>
    <DTextarea v-model="event.body" name="body" placeholder="Beschreibe das Event"
      class="border-1 mt-4 w-full rounded-lg border-slate-300" rows="10" />
    <div class="mt-4 flex space-x-2 text-sm text-slate-500">
      <div>
        <DInput id="ends_at" v-model="event.starts_at" label="Startet am" name="starts_at" type="datetime-local"
          class="border-1 w-full rounded-lg border-slate-300" />
      </div>
      <div>
        <DInput id="starts_at" v-model="event.ends_at" label="Endet am" name="ends_at" type="datetime-local"
          class="border-1 w-full rounded-lg border-slate-300" />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import supabase from '../../api/supabase'
import DButton from '../../components/DButton.vue'
import { getOrganisationId } from '../../utils/general'
import { nanoid } from 'nanoid'
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import DInput from '../../components/DInput.vue'
import DTextarea from '../../components/DTextarea.vue'
import * as yup from 'yup'
import { useForm } from 'vee-validate'

const router = useRouter()

const event = ref({
  id: nanoid(),
  // image_file_bucket_id: null,
  // image_file_name: null,
  organisation_id: getOrganisationId(),
  title: '',
  body: '',
  starts_at: null,
  ends_at: null,
  // recurrence: null,
  // created_at: '',
  // deleted_at: null,
})

const schema = yup.object({
  body: yup.string().min(1).required().label('Beschreibung'),
  title: yup.string().min(1).required().label('Titel'),
  starts_at: yup
    .date()
    .nullable()
    .required()
    .label('Startet am')
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
    .label('Endet am'),
})

const { validate } = useForm({ validationSchema: schema })

const save = async () => {
  const { valid } = await validate()
  if (!valid) return
  await supabase.from('events').insert(event.value as unknown as Event).select()
  await router.push({ name: 'event', params: { id: event.value.id } })
}
</script>
