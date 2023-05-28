<template>
  <div class="flex flex-col">
    <h4 class="text-2xl font-semibold text-gray-800">Nutzer hinzufügen</h4>
    <UsersForm v-model="userData"></UsersForm>
    <div class="mt-5 flex flex-col gap-5">
      <DButton :disabled="isCreating" look="primary" class="mt-5" @click="onCreate">Nutzer erstellen</DButton>
    </div>
  </div>
</template>

<script lang="ts" setup>
import supabase from '../../api/supabase'
import { getOrganisationId } from '../../helper/general'
import * as yup from 'yup'
import { useForm } from 'vee-validate'
import { ref } from 'vue'
import { mutate } from 'swrv'
import UsersForm from './UsersForm.vue'
import DButton from '../ui/DButton.vue'

const userData = ref({})

const createAccount = (user: any) => {
  return supabase.inviteUser(getOrganisationId(), {
    email: user.email,
    first_name: user.first_name,
    last_name: user.last_name,
    role: user.role,
  })
}

const schema = yup.object({
  email: yup.string().required().email().label('E-Mail'),
  first_name: yup.string().required().label('Vorname'),
  last_name: yup.string().required().label('Nachname'),
  role: yup.string().required().nullable().label('Rolle'),
})
const { validate, resetForm, setErrors } = useForm({
  validationSchema: schema,
  validateOnMount: false,
})

const emit = defineEmits(['created'])

const isCreating = ref(false)
const onCreate = async () => {
  if (!(await validate())?.valid) return
  isCreating.value = true
  await createAccount(userData.value)
  isCreating.value = false

  userData.value = {}
  emit('created')
}
</script>
