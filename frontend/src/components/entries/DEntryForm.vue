<template>
  <div class="mb-8 rounded-lg border border-gray-100 p-4 shadow-md">
    <div class="mb-6 flex items-baseline justify-between">
      <DInput v-model="date" name="date" type="date" class="border-1 rounded-lg border-gray-300" />
      <DButton look="primary" data-cy="button-create" @click="onCreate">Speichern</DButton>
    </div>

    <div class="mb-4">
      <label class="mb-2 flex select-none text-sm">Beschreibung</label>
      <DEntryDescription v-model="body" name="description" />
    </div>

    <div class="mb-4 flex flex-col flex-wrap items-start justify-between">
      <div class="flex flex-wrap gap-2">
        <DButton size="28" look="secondary" class="w-full space-x-2 sm:w-auto" @click="entryStore.openModal = 'events'">
          <DIcon name="calendar" />
          <div>Projekt hinzufügen</div>
        </DButton>
        <DButton size="28" look="secondary" class="w-full space-x-2 sm:w-auto" @click="entryStore.openModal = 'students'">
          <DIcon name="user-plus" />
          <div>Schüler hinzufügen</div>
        </DButton>
        <DButton size="28" look="secondary" class="w-full space-x-2 sm:w-auto" @click="openCompetenceModal">
          <DIcon name="link" />
          <div>Kompetenz hinzufügen</div>
        </DButton>
        <DButton size="28" look="secondary" class="w-full space-x-2 sm:w-auto" @click="entryStore.openModal = 'files'">
          <DIcon name="file-plus" />
          <div>Datei hochladen</div>
        </DButton>

        <DButton size="28" look="secondary" class="w-full space-x-2 sm:w-auto" @click="showTags = !showTags">
          <DIcon name="plus" />
          <div>Label hinzufügen</div>
        </DButton>
      </div>
    </div>

    <div v-if="showTags" class="mb-4">
      <DTagList v-model="currentTags" :allow-create="canCreateTags" label="Label suchen oder hinzufügen"
        placeholder="Label hinzufügen" />
    </div>

    <DEntryFiles />
    <DEntryEvents />
    <DEntryStudents />
    <DEntryCompetences />
    <DCompetenceSelection />
  </div>
</template>

<script lang="ts">
import DButton from '../ui/DButton.vue'
import DEntryCompetences from './DEntryCompetences.vue'
import DEntryStudents from './DEntryStudents.vue'
import DEntryEvents from './DEntryEvents.vue'
import DEntryDescription from './DEntryDescription.vue'
import { useRouter } from 'vue-router'
import { useEntryStore } from '../../store/entry'
import { storeToRefs } from 'pinia'
import { useSWRVS } from '../../api/helper'
import { computed, ref, watch } from 'vue'
import {
  Entry,
  EntryFile,
  EntryAccount,
  EntryAccountCompetence,
  EntryEvent,
  EntryTag,
  Tag,
} from '../../../../backend/test/types'
import supabase from '../../api/supabase'
import DEntryFiles from './DEntryFiles.vue'
import DIcon from '../ui/DIcon.vue'
import DCompetenceSelection from '../../components/competences/DCompetenceSelection.vue'
import DTagList from '../ui/DTagList.vue'
import { useStore } from '../../store/store'
import DInput from '../ui/DInput.vue'
import * as yup from 'yup'
import { useForm } from 'vee-validate'
import { getOrganisationId } from '../../helper/general'

export default {
  components: {
    DInput,
    DTagList,
    DEntryCompetences,
    DEntryStudents,
    DEntryEvents,
    DEntryDescription,
    DButton,
    DEntryFiles,
    DIcon,
    DCompetenceSelection,
  },
  props: {
    id: {
      type: String,
      default: null,
    },
  },
  setup(props: { id: string }) {
    const entryStore = useEntryStore()
    const account = useStore()

    const fetchEntry = (id: string) =>
      supabase
        .from('view_entries')
        .select('id, body, created_at, date,account:accounts!entries_account_id_fkey ( id, first_name, last_name )')
        .eq('id', id)
        .single()

    const fetchEntryAccounts = (entryId: string) =>
      supabase
        .from('entry_accounts')
        .select('*, account:accounts ( * )')
        .eq('entry_id', entryId)

    const fetchEntryEvents = (entryId: string) =>
      supabase.from('entry_events').select('*, event:events ( * )').eq('entry_id', entryId)

    const fetchEntryFiles = (entryId: string) => supabase.from('entry_files').select('*').eq('entry_id', entryId)

    const fetchEntryAccountCompetences = (entryId: string) =>
      supabase
        .from('entry_account_competences')
        .select('*, competence:competences ( * )')
        .eq('entry_id', entryId)

    const fetchEntryTags = (entryId: string) =>
      supabase.from('entry_tags').select('*, tag:tag_id(*)').eq('organisation_id', getOrganisationId()).eq('entry_id', entryId)

    // if there is an id, fetch the existing entry and populate the store
    if (props.id) {
      const { data: entry, error } = useSWRVS<Entry>(`/entries/${props.id}/edit`, fetchEntry(props.id), {
        revalidateOnFocus: false,
      })
      // TODO: handle error

      const { data: entryAccounts, error: errorAccounts } = useSWRVS<EntryAccount[]>(
        `/entries/${props.id}/accounts`,
        fetchEntryAccounts(props.id),
      )

      const { data: entryEvents, error: errorEvents } = useSWRVS<EntryEvent[]>(
        `/entries/${props.id}/events`,
        fetchEntryEvents(props.id),
        {
          revalidateOnFocus: false,
        },
      )

      const { data: entryAccountCompetences } = useSWRVS<EntryAccountCompetence[]>(
        `/entries/${props.id}/competences`,
        fetchEntryAccountCompetences(props.id),
        {
          revalidateOnFocus: false,
        },
      )

      const { data: entryFiles } = useSWRVS<EntryFile[]>(`/entries/${props.id}/files`, fetchEntryFiles(props.id), {
        revalidateOnFocus: false,
      })

      const { data: entryTags } = useSWRVS<EntryTag[]>(`/entries/${props.id}/tags`, fetchEntryTags(props.id), {
        revalidateOnFocus: false,
      })

      watch(entry, (newEntry) => {
        if (newEntry !== undefined) {
          entryStore.id = newEntry.id
          entryStore.date = newEntry.date
          entryStore.body = newEntry.body
          entryStore.account_id = newEntry.account_id
          entryStore.created_at = newEntry.created_at
        }
      })

      watch(entryEvents, (newEvent) => {
        if (newEvent !== undefined) {
          entryStore.entry_events = newEvent
        }
      })

      watch(entryAccounts, (newEntryAccounts) => {
        if (newEntryAccounts !== undefined) {
          entryStore.entry_accounts = newEntryAccounts
        }
      })

      watch(entryAccountCompetences, (newEntryAccountCompetences) => {
        if (newEntryAccountCompetences !== undefined) {
          entryStore.entry_account_competences = newEntryAccountCompetences
        }
      })

      watch(entryFiles, (newEntryFiles) => {
        if (newEntryFiles !== undefined) {
          entryStore.entry_files = newEntryFiles
        }
      })

      watch(entryTags, (newEntryTags) => {
        if (newEntryTags !== undefined) {
          entryStore.entry_tags = newEntryTags
          currentTags.value = newEntryTags
            .filter((tag) => tag.deleted_at === null)
            .map((tag) => (tag as unknown as { tag: Tag }).tag)
          if (currentTags.value.length > 0) {
            showTags.value = true
          }
        }
      })
    }

    const showTags = ref(false)
    const currentTags = ref<Tag[]>([])

    const canCreateTags = computed(() => !['student', 'teacher_guest'].includes(account.account.role))

    watch(
      currentTags,
      (newTags: Tag[]) => {
        if (newTags !== undefined) {
          const ids = newTags.map((tag) => tag.id)
          for (const tag of newTags) {
            entryStore.addTag(tag)
          }

          for (const tag of entryStore.entry_tags) {
            if (!ids.includes(tag.tag_id)) {
              entryStore.removeTag(tag)
            }
          }
        }
      },
      { deep: true },
    )

    const router = useRouter()

    const { date, body, entry_accounts } = storeToRefs(entryStore)

    const schema = yup.object({
      //description: yup.string().min(1).required().label('Beschreibung'),
      description: yup.object().required().label('Beschreibung'),
      date: yup.string().required().label('Datum'),
    })

    const { validate } = useForm({ validationSchema: schema })

    const onCreate = async () => {
      const { valid } = await validate()
      if (!valid) return alert('Bitte fülle alle erforderlichen Felder aus')

      const data = await entryStore.save()
      await router.push({ name: 'entry', params: { id: data.id } })
    }

    const openCompetenceModal = () => {
      if (entryStore.entry_accounts.length > 0) {
        entryStore.openModal = 'competences'
      } else {
        alert('Bitte fügen einen Schüler hinzu, bevor du eine Kompetenz hinzufügst')
      }
    }

    return {
      entryStore,
      props,
      body,
      date,
      onCreate,
      entry_accounts,
      openCompetenceModal,
      showTags,
      currentTags,
      canCreateTags,
    }
  },
}
</script>
