<template>
  <div class="mx-auto mt-12 grid max-w-[500px] gap-4">
    <div>
      <label for="student" class="mb-1 block text-sm uppercase text-gray-500">Schüler</label>
      <DDropdown id="student" v-model="store.student_account_id" name="student_account_id" :options="studentsOptions"
        data-cy="student"></DDropdown>
    </div>

    <div>
      <label for="from" class="mb-1 block text-sm uppercase text-gray-500">Von</label>
      <DInput id="from" v-model="store.from" name="from" type="date" data-cy="from"
        class="w-full rounded-lg border-gray-300" />
    </div>

    <div>
      <label for="to" class="mb-1 block text-sm uppercase text-gray-500">Bis</label>
      <DInput id="to" v-model="store.to" type="date" name="to" data-cy="to" class="w-full rounded-lg border-gray-300" />
    </div>

    <div>
      <label for="type" class="mb-1 block text-sm uppercase text-gray-500">Art</label>
      <DDropdown v-model="store.type" :options="reportTypes" name="type" data-cy="type"> </DDropdown>
    </div>

    <div v-if="store.type === 'report'">
      <label for="tags" class="mb-1 block text-sm uppercase text-gray-500">Einträge mit mindestens diesem Label</label>
      <DTagList v-model="store.filter_tags" :allow-create="false" label="Label suchen" placeholder="Label hinzufügen">
      </DTagList>
    </div>

    <DButton look="primary" data-cy="create" @click="createReport">Erstellen</DButton>
  </div>
</template>

<script>
import DButton from '../../../components/ui/DButton.vue'
import { useReportStore } from '../../../store/report'
import supabase from '../../../api/supabase'
import { useSWRVS } from '../../../api/helper'
import { useRouter } from 'vue-router'
import { getOrganisationId } from '../../../helper/general'
import DDropdown from '../../../components/ui/DDropdown.vue'
import { computed } from 'vue'
import DInput from '../../../components/ui/DInput.vue'
import * as yup from 'yup'
import { useForm } from 'vee-validate'
import DTagList from '../../../components/ui/DTagList.vue'

const reportTypes = [
  { value: 'report', label: 'Einträge' },
  { value: 'subjects', label: 'Fächer' },
  { value: 'report_docx', label: 'Einträge als .docx' },
  { value: 'subjects_docx', label: 'Fächer als .docx' },
]

export default {
  components: { DInput, DDropdown, DButton, DTagList },
  setup() {
    const store = useReportStore()
    const router = useRouter()

    // make sure the store is clean
    store.$reset()

    const fetchAccounts = () => {
      return supabase
        .from('accounts')
        .select('id, first_name, last_name')
        .eq('organisation_id', getOrganisationId())
        .eq('role', 'student')
        .is('deleted_at', null)
        .limit(200)
        .order('first_name, last_name', { ascending: true })
    }

    const { data: students } = useSWRVS(`/reports/new/students`, fetchAccounts())

    const studentsOptions = computed(() => {
      return (
        students.value?.map((student) => {
          return {
            value: student.id,
            label: `${student.first_name} ${student.last_name}`,
          }
        }) || []
      )
    })

    const schema = yup.object({
      student_account_id: yup.string().nullable().min(1).required().label('Schüler'),
      type: yup.string().min(1).required().label('Art'),
      from: yup
        .date()
        .nullable()
        .required()
        .label('Von')
        .typeError('Von ist ein Pflichtfeld')
        .max(
          yup.ref('to', {
            map: (value) => {
              return isFinite(value) && value ? value : new Date('9999-01-01')
            },
          }),
          'Von muss früher sein als Bis',
        ),
      to: yup
        .date()
        .min(
          yup.ref('from', {
            map: (value) => {
              return isFinite(value) && value ? value : new Date('0000-01-01')
            },
          }),
          'Bis muss später sein als Von',
        )
        .nullable()
        .required()
        .typeError('Bis ist ein Pflichtfeld')
        .label('Bis'),
    })

    const { validate } = useForm({ validationSchema: schema, validateOnMount: false })

    const createReport = async () => {
      const { valid } = await validate()
      if (!valid) return

      await store.create()
      await store.$reset()
      await router.push({ name: 'reports' })
    }

    return {
      store,
      createReport,
      students,
      studentsOptions,
      reportTypes,
    }
  },
}
</script>
