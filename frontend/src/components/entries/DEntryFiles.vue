<template>
  <div class="flex flex-wrap space-x-2">
    <div v-for="file in entryStore.files" :key="file.id"
      class="mb-2 inline-flex rounded-lg bg-slate-100 p-1 text-slate-700">
      <div>{{ decodeFileName(file.file_name) }}</div>
      <div class="ml-1 cursor-pointer rounded-lg hover:bg-slate-200" @click="entryStore.deleteFile(file)">
        <IconX />
      </div>
    </div>
  </div>
  <DModal :open="open" @close="open = false">
    <div class="mb-4">Datei auswählen oder hierher ziehen</div>
    <input type="file" name="" placeholder="Drag and drop files here"
      class="flex min-h-[30vh] w-full items-center justify-center rounded-lg border border-dashed p-4 text-slate-500 file:hidden focus:ring-2"
      @change="onFileChange" />
  </DModal>
</template>

<script lang="ts" setup>
import DModal from '../ui/DModal.vue'
import { computed } from 'vue'
import supabase from '../../api/supabase'
import { nanoid } from 'nanoid'
import { useEntryStore } from '../../store/entry'
import IconX from '../icons/IconX.vue'
import { decodeFileName, encodeFileName } from '../../helper/entryFiles'
import { getOrganisationId } from '../../helper/general'

const entryStore = useEntryStore()
const open = computed({
  get: () => entryStore.openModal === 'files',
  set: (value) => (value ? (entryStore.openModal = 'files') : (entryStore.openModal = '')),
})

const onFileChange = async (e: any) => {
  const file = e.target.files[0]

  const id = nanoid()
  const entryFile = {
    id,
    file_bucket_id: `org_${getOrganisationId()}`,
    file_name: `entries/${entryStore.id}/${id}-${encodeFileName(file.name)}`,
    entry_id: entryStore.id,
    deleted_at: null,
    created_at: new Date().toISOString(),
  }

  const { data, error } = await supabase.storage.from(entryFile.file_bucket_id).upload(entryFile.file_name, file, {
    cacheControl: '3600',
    upsert: false,
  })

  if (!error) {
    entryStore.entry_files.push(entryFile)
  }

  e.target.value = ''
  open.value = false
}
</script>
