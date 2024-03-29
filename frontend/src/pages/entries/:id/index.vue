<template>
  <div v-if="entry">
    <div class="flex items-start justify-between">
      <div>
        <div class="mb-3 text-gray-500">{{ parseDateCalendar(entry.date) }}</div>
        <div data-cy="entry-body" class="[&>*]:mb-3" v-html="renderEntryBody(entry.body)"></div>
        <div class="mt-5 mb-4 text-sm font-medium text-gray-500">
          Erstellt am <span class="text-gray-700">{{ parseDate(entry.created_at) }}</span> von
          <span class="text-gray-700">{{ `${entry.account.first_name} ${entry.account.last_name}` }}</span>
        </div>
        <div v-if="entry?.entry_tags?.filter((el) => el.deleted_at === null).length > 0" class="mt-2.5">
          <div class="mb-2 text-sm uppercase text-gray-500">Labels</div>
          <div class="flex flex-wrap gap-2.5">
            <DTag v-for="entry_tag in entry.entry_tags?.filter((el) => el.deleted_at === null)">
              {{ entry_tag.tag.name }}
            </DTag>
          </div>
        </div>
      </div>
      <div class="flex items-start space-x-2">
        <DButton look="secondary" size="28" :to="{ name: 'entry_edit', params: { id } }">Bearbeiten</DButton>
        <DButton look="danger-light" size="28" @click="deleteEntry">
          <DIcon name="trash" color="red" size="20" />
          <div class="ml-1" data-cy="delete">Archivieren</div>
        </DButton>
      </div>
    </div>
    <div v-if="entry?.entry_files?.filter((el) => el.deleted_at === null).length > 0" class="mt-8">
      <div class="mb-2 text-sm uppercase text-gray-500">Dateien</div>
      <div class="flex flex-wrap space-x-2">
        <div v-for="file in entry.entry_files.filter((el) => el.deleted_at === null)" :key="file.id"
          class="mb-2 inline-flex cursor-pointer rounded-lg border px-2 py-1 text-gray-700 hover:text-blue-600"
          tabindex="0" @keydown.enter="downloadFile(file)" @click="downloadFile(file)">
          <div>{{ decodeFileName(file.file_name) }}</div>
        </div>
      </div>
    </div>
    <div v-if="entry?.entry_events?.filter((el) => el.deleted_at === null).length > 0" class="mt-8">
      <div class="mb-2 text-sm uppercase text-gray-500">Events</div>
      <div class="grid grid-cols-1 gap-2 sm:grid-cols-3">
        <router-link v-for="entry_event in entry.entry_events.filter((el) => el.deleted_at === null)"
          :key="entry_event.id" :to="{ name: 'event', params: { id: entry_event.event.id } }"
          class="rounded-lg border p-4 hover:shadow">
          <div class="mb-1 font-medium">{{ entry_event.event.title }}</div>
          <div class="text-sm text-gray-700">{{ entry_event.event.body.slice(0, 50) }}</div>
        </router-link>
      </div>
    </div>
    <div v-if="entry?.entry_accounts?.filter((el) => el.deleted_at === null).length > 0" class="mt-6">
      <div class="mb-2 text-sm uppercase text-gray-500">
        {{ entry.entry_accounts.filter((el) => el.deleted_at === null).length }} Schüler
      </div>
      <div class="flex flex-wrap gap-2">
        <router-link v-for="entry_account in entry.entry_accounts.filter((el) => el.deleted_at === null)"
          :key="entry_account.id" class="rounded-lg bg-gray-100 p-2 hover:shadow"
          :to="{ name: 'student', params: { id: entry_account.account.id } }">
          {{ entry_account.account.first_name }} {{ entry_account.account.last_name }}
        </router-link>
      </div>
    </div>
    <div v-if="entry?.entry_account_competences?.filter((el) => el.deleted_at === null).length > 0" class="mt-6">
      <div class="mb-2 cursor-pointer text-sm uppercase text-gray-500">
        {{ reduceEACsToCompetences(entry.entry_account_competences).length }} Kompetenzen
      </div>
      <div class="flex flex-col space-y-3">
        <DEntryAccountCompetence v-for="eac in reduceEACsToCompetences(entry.entry_account_competences)" :key="eac.id"
          :eac="eac" data-cy="entry-competence" />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import supabase from '../../../api/supabase'
import { useSWRVS } from '../../../api/helper'
import { Entry } from '../../../../../backend/test/types'
import { useRoute, useRouter } from 'vue-router'
import { renderEntryBody } from '../../../helper/renderJSON'
import { parseDate, parseDateCalendar } from '../../../helper/parseDate'
import DButton from '../../../components/ui/DButton.vue'
import DEntryAccountCompetence from '../../../components/DEntryAccountCompetence.vue'
import { reduceEACsToCompetences } from '../../../store/entry'
import { decodeFileName } from '../../../helper/entryFiles'
import { downloadFile } from '../../../helper/general'
import IconMoreHorizontal from '../../../components/icons/IconMoreHorizontal.vue'
import { ref } from 'vue'
import DIcon from '../../../components/ui/DIcon.vue'
import { createModal } from '../../../helper/Modal'
import { PageModalProps } from '../../../components/ui/DConfirmModal.vue'
import DTag from '../../../components/ui/DTag.vue'

const route = useRoute()
const router = useRouter()

const deleteEntry = async () => {
  let confirmed = await createModal({
    title: 'Eintrag archivieren',
    description: 'Bist du sicher, dass du diesen Eintrag archivieren willst?',
    confirm: 'Archivieren',
    cancel: 'Abbrechen',
  } as PageModalProps)
  if (!confirmed) return

  await supabase
    .from('entries')
    .delete()
    .eq('id', route.params.id as string).select()

  await router.push({ name: 'entries' })
}

// Try changing 'accounts' to one of the following: 'accounts!entries_account_id_fkey', 'accounts!entry_accounts', 'accounts!entry_account_competences'. Find the desired relationship in the 'details' key.
const fetchEntries = (id: string) =>
  supabase
    .from('entries')
    .select(
      `
id, 
body, 
created_at, 
date, 
entry_accounts (
  *, 
  account:account_id (*)
), 
entry_files (*), 
entry_events (
  *,
  event:event_id (*)
), 
date, 
account:accounts!entries_account_id_fkey ( 
  * 
), 
entry_account_competences (
  *, 
  competence:competence_id (*)
), 
entry_tags (
  *, 
  tag:tag_id(*)
)
`,
    )
    .eq('id', id)
    .single()

const { data: entry } = useSWRVS<Entry>(`/entries/${route.params.id}`, fetchEntries(route.params.id as string))

const id = route.params.id
</script>
