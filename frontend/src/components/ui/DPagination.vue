<template>
  <div class="flex items-center justify-between border-t border-slate-200 bg-white py-3">
    <div class="flex flex-1 justify-between sm:hidden">
      <button
        class="relative inline-flex items-center rounded-md border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
        @click="prev"
      >
        Zurück
      </button>
      <button
        class="relative ml-3 inline-flex items-center rounded-md border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
        @click="next"
      >
        Weiter
      </button>
    </div>
    <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
      <div v-if="showResults">
        <p v-if="count > 0" class="text-sm text-slate-700">
          <span class="font-medium">{{ count }}</span> Ergebnisse
        </p>
      </div>
      <div v-if="showInput" class="mr-4 flex items-center text-sm text-slate-700">
        Seite:
        <DInput v-model="currentPage" type="number" min="1" :max="totalPages" class="ml-2 w-24" />
      </div>
      <div class="flex items-center">
        <nav class="relative z-0 inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
          <button
            class="relative inline-flex items-center rounded-l-md border border-slate-300 bg-white px-2 py-2 text-sm font-medium text-slate-500 hover:bg-slate-50"
            :disabled="currentPage === 1"
            @click="prev"
          >
            <span class="sr-only">Previous</span>
            <ChevronLeftIcon class="h-5 w-5" aria-hidden="true" />
          </button>
          <template v-if="count > 0">
            <template v-for="_page in filteredPages" :key="_page">
              <button
                v-if="Number.isInteger(_page)"
                aria-current="page"
                :class="{
                  'z-10 border-blue-500  bg-blue-50 text-blue-600': currentPage === _page + 1,
                  'border-slate-300 text-slate-500': currentPage !== _page + 1,
                }"
                class="relative inline-flex items-center border px-4 py-2 text-sm font-medium"
                @click="currentPage = _page + 1"
              >
                {{ _page + 1 }}
              </button>
              <div
                v-else
                class="relative inline-flex items-center border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700"
              >
                ...
              </div>
            </template>
          </template>
          <button
            class="relative inline-flex items-center rounded-r-md border border-slate-300 bg-white px-2 py-2 text-sm font-medium text-slate-500 hover:bg-slate-50"
            :disabled="currentPage === totalPages"
            @click="next"
          >
            <span class="sr-only">Next</span>
            <ChevronRightIcon class="h-5 w-5" aria-hidden="true" />
          </button>
        </nav>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { ChevronLeftIcon, ChevronRightIcon } from '@heroicons/vue/solid'
import { computed, ref, watch } from 'vue'
import DInput from './DInput.vue'

export const paginationProps = {
  offset: 0,
  limit: 10,
}

export default {
  components: {
    DInput,
    ChevronLeftIcon,
    ChevronRightIcon,
  },
  props: {
    count: {
      type: Number,
      default: -1,
    },
    limit: {
      type: Number,
      default: 10,
    },
    offset: {
      type: Number,
      default: 1,
    },
    showResults: {
      type: Boolean,
      default: true,
    },
    showInput: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['change'],
  setup(props: any, { emit }: any) {
    const totalPages = computed(() => Math.ceil(props.count / props.limit))
    const currentPageRef = ref(Math.ceil(props.offset / props.limit) + 1)

    watch(
      () => props.offset,
      (newOffset: number) => {
        currentPageRef.value = Math.ceil(newOffset / props.limit) + 1
      },
    )

    const currentPage = computed({
      set: (value) => {
        currentPageRef.value = value
        emit('change', value * props.limit - props.limit)
      },
      get: () => currentPageRef.value,
    })

    const next = () => {
      if (currentPage.value < totalPages.value || totalPages.value <= 0) {
        currentPage.value++
      }
    }

    const prev = () => {
      if (currentPage.value > 1) {
        currentPage.value--
      }
    }

    const filteredPages = computed(() => {
      const itemsVisible = 5
      let diff = itemsVisible / 2
      let pages = [...Array(totalPages.value).keys()].slice(2, -2)
      let result = []

      if (pages.length > itemsVisible) {
        let diffFirst = currentPage.value - pages[0]
        let diffLast = currentPage.value - pages[pages.length - 1]

        //if page is near the beginning
        if (diffFirst < diff) {
          pages = pages.slice(0, itemsVisible)
        }
        //if page is near the end
        else if (diffLast >= -diff) {
          pages = pages.slice(-itemsVisible)
        }
        //  if page is in the middle
        else {
          pages = pages.filter((page) => {
            let diffPage = currentPage.value - page
            return diffPage < 0 ? Math.abs(diffPage) <= diff : diffPage < diff
          })
        }

        result = [
          //replace the second page with ... if not in pages
          pages[0] - 1 === 1 ? 1 : '...',
          ...pages,
          //replace the second to last page with ... if not in pages
          pages[pages.length - 1] + 1 === totalPages.value - 2 ? totalPages.value - 2 : '...',
        ]
      } else if (totalPages.value > 2) {
        //return all pages minus the first and last
        result = [...Array(totalPages.value - 2).keys()].map((page) => page + 1)
      }

      return [0, ...result, totalPages.value - 1]
    })

    return {
      totalPages,
      currentPage,
      next,
      prev,
      filteredPages,
    }
  },
}
</script>
