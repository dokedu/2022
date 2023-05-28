<template>
  <div v-if="student" class="mt-8">
    <div class="flex">
      <div class="mr-5 h-24 w-24 rounded-full bg-gray-200">
        <img v-if="avatar?.signedUrl" class="h-24 w-24 rounded-full object-cover" :src="avatar?.signedUrl" alt="Avatar" />
      </div>
      <div class="flex flex-col mt-3 ">
        <div class="text-xl font-medium text-blue-600">{{ student.first_name }} {{ student.last_name }}</div>
        <div class="mt-2 text-base text-gray-600">Klassenstufe: {{ student.grade }}</div>
      </div>
    </div>
    <DStudentEntries :student="student" />
    <div class="cursor-default mt-6 mb-4 pb-8 flex justify-between items-center">
      <h2 class="mb-2 text-xl">Kompetenzen</h2>
      <router-link class="text-blue-700 px-2 py-1 rounded-md hover:bg-gray-100" :to="{ name: 'student-competences' }">Zu
        den Kompetenzen</router-link>

    </div>
  </div>
</template>

<script lang="ts" setup>
import supabase from '../../../api/supabase'
import { useSWRVS } from '../../../api/helper'
import { Account } from '../../../../../backend/test/types/index'
import { useRoute } from 'vue-router'
import useSWRV from 'swrv'
import DStudentEntries from '../../../components/students/DStudentEntries.vue'

const route = useRoute()

const fetchAccount = () =>
  supabase
    .from('accounts')
    .select('id, first_name, last_name, avatar_file_bucket_id, avatar_file_name, grade')
    .eq('role', 'student')
    .is('deleted_at', null)
    .eq('id', route.params.id)
    .single()

const { data: student } = useSWRVS<Account[]>(`/students/${route.params.id}`, fetchAccount())

const fetchAvatarURL = (from: string, path: string) => supabase.storage.from(from).createSignedUrl(path, 60)

const { data: avatar } = useSWRV(
  () => student?.value?.avatar_file_bucket_id && `/students/${student.value.id}/avatarURL`,
  () => fetchAvatarURL(student?.value?.avatar_file_bucket_id, student?.value?.avatar_file_name),
)
</script>
