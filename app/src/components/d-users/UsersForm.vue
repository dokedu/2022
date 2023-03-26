<template>
  <div class="mt-5 flex flex-col gap-5">
    <DInput v-model.trim="currentUser.first_name" class="w-full" name="first_name" label="Vorname"></DInput>
    <DInput v-model.trim="currentUser.last_name" class="w-full" name="last_name" label="Nachname"></DInput>

    <template v-if="role === 'student' || currentUser.role === 'student'">
      <DInput :model-value="joinedAt" type="date" class="w-full" label="Beigetreten am" name="joined_at"
        @update:model-value="currentUser.joined_at = $event"></DInput>
      <DInput :model-value="leftAt" type="date" class="w-full" name="left_at" label="Verlassen am"
        @update:model-value="currentUser.left_at = $event"></DInput>
      <DInput :model-value="birthday" type="date" class="w-full" label="Geburtstag" name="birthday"
        @update:model-value="currentUser.birthday = $event"></DInput>
      <DInput :model-value="grade" type="number" class="w-full" label="Klassenstufe" name="grade"
        @update:model-value="currentUser.grade = $event"></DInput>
    </template>

    <DInput v-if="!currentUser.id && !role" v-model="currentUser.email" type="email" name="email" label="E-Mail">
    </DInput>
    <DDropdown v-if="!role" v-model="currentUser.role" :options="filteredRoles" name="role" label="Rolle"></DDropdown>
  </div>
</template>

<script lang="ts">
import DInput from '../DInput.vue'
import DDropdown, { DropdownOption } from '../DDropdown.vue'
import { computed, defineComponent, reactive, toRef, watch } from 'vue'

export default defineComponent({
  name: 'UsersForm',
  components: { DDropdown, DInput },
  props: {
    role: {
      type: String,
      default: null,
    },
    modelValue: {
      type: Object,
      default: () => ({
        first_name: '',
        last_name: '',
        email: '',
        role: null,
      }),
    },
  },
  emits: ['update:modelValue'],
  setup(props, { emit }) {
    const currentUser = reactive({ ...props.modelValue })
    const roles = [
      { label: 'Eigentümer', value: 'owner' },
      { label: 'Lehrer', value: 'teacher' },
      { label: 'Gast-Lehrer', value: 'teacher_guest' },
      { label: 'Admin', value: 'admin' },
    ] as DropdownOption[]

    const filteredRoles = computed(() => roles.filter((role) => currentUser.id || role.value !== 'owner'))

    const birthday = computed(() => {
      if (currentUser.birthday || currentUser.birthday) {
        return new Date(currentUser.birthday || currentUser.birthday).toISOString().split('T')[0]
      }
      return ''
    })

    const joinedAt = computed(() => {
      if (currentUser.joined_at || currentUser.created_at) {
        return new Date(currentUser.joined_at || currentUser.created_at).toISOString().split('T')[0]
      }
      return ''
    })

    const leftAt = computed(() => {
      if (currentUser.left_at) {
        return new Date(currentUser.left_at).toISOString().split('T')[0]
      }
      return ''
    })

    watch(
      currentUser,
      () => {
        let data = currentUser
        if (props.role) {
          data = { ...data, role: props.role }
        }
        emit('update:modelValue', data)
      },
      { deep: true },
    )

    return {
      joinedAt,
      leftAt,
      birthday,
      currentUser,
      filteredRoles,
      grade: currentUser.grade
    }
  },
})
</script>

<style scoped>
</style>
