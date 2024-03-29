<template>
  <div v-if="store.id && store.author_account" data-cy="report" class="flex max-w-[500px] flex-col">
    <div class="mb-4 flex items-center space-x-2" data-cy="name">
      <div class="text-xl">{{ store.student_account.first_name }} {{ store.student_account.last_name }}</div>

      <DReportStatus :status="store.status" />
    </div>

    <div class="mb-4 flex space-x-2">
      <div data-cy="from">
        {{ parseDateCalendar(store.from) }}
      </div>
      <div>-</div>
      <div data-cy="to">
        {{ parseDateCalendar(store.to) }}
      </div>
    </div>
    <div class="mb-8 text-sm text-gray-500" data-cy="teacher">
      <span>Erstellt von </span>
      <span class="text-gray-700">{{ store.author_account.first_name }} {{ store.author_account.last_name }}</span>
    </div>

    <div v-if="store.status === 'error' && store.meta?.error" class="mb-8 rounded-md bg-red-50 p-2">
      <div class="flex">
        <div>
          <h3 class="text-sm font-medium text-red-800 p-1">Fehler bei der Erstellung des Berichts</h3>
          <div class="mt-2 text-sm text-red-700 font-mono p-3 bg-red-100 rounded-md">
            {{ store.meta.error }}
          </div>
        </div>
      </div>
    </div>
    <DButton look="secondary" data-cy="viewPDF" @click="viewFile">{{ buttonLabel }}</DButton>
  </div>
</template>

<script lang="ts" setup>
import { useReportStore } from '../../../store/report'
import { computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { parseDateCalendar } from '../../../helper/parseDate'
import DButton from '../../../components/ui/DButton.vue'
import DReportStatus from '../../../components/reports/DReportStatus.vue'

const store = useReportStore()
const route = useRoute()

onMounted(async () => {
  await store.loadReport(route.params.id)
})

const buttonLabels = {
  report_docx: 'Dokument ansehen',
  subjects_docx: 'Dokument ansehen',
  report: 'PDF ansehen',
  subjects: 'PDF ansehen',
}
const buttonLabel = computed(() => buttonLabels[store.type || 'report'])

const viewFile = async () => {
  if (store.status === 'done') {
    try {
      const url = await store.createSignedUrl()
      if (url) {
        window.open(url, '_blank')
      }
    } catch (e) {
      // console.error(e)
    }
  } else if (store.status === 'pending') {
    alert(
      'Dieser Bericht ist noch nicht fertiggestellt. Lade die Seite in einigen Sekunden neu, um den fertigen Bericht zu sehen.',
    )
  } else {
    alert('Dieser Bericht ist fehlgeschlagen. Bitte kontaktieren den Support unter help@dokedu.org.')
  }
}
</script>
