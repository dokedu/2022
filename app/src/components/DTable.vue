<template>
  <div class="flex flex-col">
    <div class="-my-2 overflow-x-auto lg:overflow-x-visible">
      <div class="inline-block py-2 align-middle sm:min-w-full lg:w-full lg:px-0">
        <div class="overflow-hidden rounded-md border-slate-200">
          <table class="min-w-full divide-y divide-slate-200">
            <thead class="bg-slate-100">
              <tr>
                <th v-if="selectable">
                  <FormCheckbox
                    :model-value="items.length === selectedItems.length"
                    class="items-center self-stretch px-6"
                    @change="selectAll"
                  ></FormCheckbox>
                </th>
                <th
                  v-for="column in filteredColumns"
                  :key="`${column.key}-${currentSorting?.key === column.key ? currentSorting?.order : ''}`"
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-slate-500"
                  :class="{ 'cursor-pointer hover:text-slate-600 focus:text-slate-700': column.sortable }"
                  @click="() => sortBy(column)"
                >
                  <div class="flex select-none items-center">
                    {{ column.name }}
                    <div v-if="column.sortable && currentSorting?.key === column.key" class="ml-2 flex">
                      <SortDescendingIcon v-if="currentSorting?.order !== 'asc'" class="h-5 w-5"></SortDescendingIcon>
                      <SortAscendingIcon v-else class="h-5 w-5"></SortAscendingIcon>
                    </div>
                  </div>
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-200 bg-white">
              <tr
                v-for="item in items"
                :key="item[itemKey]"
                class="cursor-pointer transition-colors hover:bg-slate-100"
              >
                <td v-if="selectable">
                  <FormCheckbox
                    :model-value="selectedItems.includes(item[itemKey])"
                    class="items-center self-stretch px-6"
                    @change="() => select(item)"
                  ></FormCheckbox>
                </td>
                <td
                  v-for="column in columns"
                  :key="`${item[itemKey]}-column-${column.key}`"
                  class="whitespace-nowrap px-6 py-4"
                  @click="$emit('open', item)"
                >
                  <slot v-if="!!$slots[column.key]" :name="column.key" :item="item" :column="item[column.key]"></slot>
                  <template v-else>
                    {{ item[column.key] || 0 }}
                  </template>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import FormCheckbox from './DCheckbox.vue'
import { ref, watch } from 'vue'
import { SortAscendingIcon, SortDescendingIcon } from '@heroicons/vue/outline'

export interface TableColumn {
  name: string
  key: string
  sortable: boolean
  order: string
}

export interface PageTableProperties {
  columns: TableColumn[]
  items: any[] | undefined | null
  itemKey: string
  selectable: boolean
  sorting: TableColumn
  modelValue: any[] //selected items -> item[itemKey]
}

export default {
  name: 'DTable',
  components: { FormCheckbox, SortAscendingIcon, SortDescendingIcon },
  props: {
    modelValue: {
      type: Array,
      default: () => [],
    },
    sorting: {
      type: Object,
      default: () => {
        return {
          key: 'createdAt',
          order: 'desc',
        } as TableColumn
      },
    },
    selectable: {
      type: Boolean,
      default: false,
    },
    items: {
      type: Array,
      required: true,
    },
    itemKey: {
      type: String,
      default: 'id',
    },
    columns: {
      type: Array,
      required: true,
      default: () => [] as TableColumn[],
    },
  },
  emits: ['open', 'update:modelValue', 'update:sorting'],
  setup(props: PageTableProperties, { emit }) {
    const filteredColumns = ref<TableColumn[]>(props.columns)

    /**
     * Sorting
     */
    const currentSorting = ref<TableColumn | null>(Object.assign({ order: 'desc' }, props.sorting))
    const sortBy = (column: TableColumn) => {
      if (!column.sortable) return

      if (!column.order) {
        column.order = 'desc'
      }

      if (column.key === currentSorting.value?.key) {
        column.order = column.order === 'asc' ? 'desc' : 'asc'
      }

      currentSorting.value = column
      filteredColumns.value = [...filteredColumns.value]
    }

    watch(
      currentSorting,
      () => {
        emit('update:sorting', currentSorting.value)
      },
      { deep: true, immediate: true },
    )

    /**
     * Select function stuff
     */
    const selectedItems = ref(props.modelValue || [])
    const selectAll = (all: boolean) => {
      selectedItems.value = all ? props.items.map((i: any) => i[props.itemKey]) : []
    }

    const select = (item: any) => {
      if (selectedItems.value.includes(item[props.itemKey])) {
        selectedItems.value = selectedItems.value.filter((id) => id !== item[props.itemKey])
        return
      }

      selectedItems.value.push(item[props.itemKey])
    }

    watch([selectedItems], () => {
      emit('update:modelValue', selectedItems.value)
    })

    return {
      filteredColumns,
      selectAll,
      select,
      selectedItems,
      sortBy,
      currentSorting,
    }
  },
}
</script>
