<template>
  <div class="relative flex min-w-[200px] flex-col">
    <label v-if="label" class="mb-1 text-xs text-gray-500">{{ label }}</label>
    <label ref="dropdownInput"
      class="relative cursor-pointer items-center rounded-md bg-gray-100 py-2.5 pl-3 pr-10 text-left align-middle text-gray-700 sm:text-sm"
      :class="{ 'border-blue-500 outline-none ring-1 ring-blue-500 ': state.isOpen }">
      <input ref="searchRef" v-model="search" :type="searchable ? 'text' : 'button'"
        class="absolute top-1.5 left-3 right-3 z-0 w-full border-0 bg-transparent py-0 px-0 pr-10 focus:outline-none focus:ring-0"
        @focusin="state.isOpen = true" @keydown.down.prevent="selectNext" @keydown.up.prevent="selectPrevious"
        @keydown.enter.prevent="onEnter" />
      <div class="pointer-events-none z-10 flex h-full items-center">
        <template v-if="search.length <= 0">
          {{ dropdownLabel }}
        </template>
        <template v-else>&nbsp;</template>
      </div>
      <span class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
        <SelectorIcon class="h-5 w-5 text-gray-400" aria-hidden="true" />
      </span>
    </label>

    <small v-if="errorMessage" class="text-red-400">{{ errorMessage }}</small>

    <div ref="dropdownMenu" class="relative">
      <transition leave-active-class="transition ease-in duration-100" leave-from-class="opacity-100"
        leave-to-class="opacity-0">
        <ul v-if="state.isOpen"
          class="absolute top-0 z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm"
          :class="{ '-top-12 -translate-y-full': openOnTop }">
          <li v-if="!filteredOptions.length" class="py-2 pl-8">Keine Treffer gefunden</li>
          <li v-for="(option, index) in filteredOptions" :key="option.value"
            class="relative cursor-pointer select-none py-2 pl-8 pr-4 text-gray-900 hover:bg-blue-600 hover:text-white"
            :class="{ 'bg-blue-600 text-white': index === focusedOptionIndex }" @click="selectedOptions = option">
            <span :class="[selectedOptionIndexes.includes(index) ? 'font-semibold' : 'font-normal', 'block truncate']">
              {{ option.label }}
            </span>
            <span v-if="selectedOptionIndexes.includes(index)" class="absolute inset-y-0 right-0 flex items-center pr-4">
              <CheckIcon class="h-5 w-5" aria-hidden="true"></CheckIcon>
            </span>
          </li>
        </ul>
      </transition>
    </div>
  </div>
</template>

<script lang="ts">
import { computed, ComputedRef, defineComponent, reactive, ref, toRef, watch, WritableComputedRef } from 'vue'
import { CheckIcon, SelectorIcon } from '@heroicons/vue/solid'
import { useField } from 'vee-validate'

export interface DropdownOption {
  value: string | number | symbol | undefined
  label: string
  data?: object | undefined
}

interface DropdownState {
  isOpen: boolean
  selected: unknown[]
  search: string
}

export default defineComponent({
  components: { CheckIcon, SelectorIcon },
  props: {
    modelValue: {
      type: [String, Number, Boolean, Object, Array],
      default: null,
    },
    name: {
      type: String,
      default: '',
    },
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: 'Wähle eine Option',
    },
    searchable: {
      type: Boolean,
      default: true,
    },
    multiple: {
      type: Boolean,
      default: false,
    },
    openOnTop: {
      type: Boolean,
      default: false,
    },
    options: {
      type: Array as () => DropdownOption[],
      default: () => [] as DropdownOption[],
    },
  },
  emits: ['update:modelValue', 'search', 'blur'],
  setup(props, { emit, expose }) {
    const focusedOptionIndex = ref<number>(-1)
    const searchRef = ref()
    const state = reactive({
      isOpen: false,
      selected: Array.isArray(props.modelValue) ? props.modelValue : [props.modelValue],
      search: '',
    } as DropdownState)

    const name = toRef(props, 'name')
    const { value: model, errorMessage } = useField(name, undefined, {
      initialValue: toRef(props, 'modelValue'),
      validateOnMount: false,
    })

    //ToDo: check perfromance we have a lot of watchers here
    watch(
      () => props.modelValue,
      (value) => {
        state.selected = Array.isArray(value) ? value : [value]
      },
    )

    /**
     * Search function
     */
    const search = computed({
      set: (value) => {
        state.search = value
        if (value) {
          selectedOptions.value = undefined
        }
      },
      get: () => state.search,
    }) as WritableComputedRef<string>

    // enables us to query specific for searches
    watch(search, (value) => {
      emit('search', value)
    })

    /**
     * Select functionality
     */

    const filteredOptions = computed(() => {
      let options = props.options.filter((option: DropdownOption) => {
        return option.label.toLowerCase().includes(search.value.toLowerCase())
      })

      if (props.multiple) {
        options = options.sort((a: DropdownOption, b: DropdownOption) => {
          return state.selected.includes(a.value) && !state.selected.includes(b.value) ? -1 : 1
        })
      }

      return options
    }) as ComputedRef<DropdownOption[]>

    const selectedOptionIndexes = computed(() => {
      return state.selected.map((selected: unknown) =>
        filteredOptions.value.findIndex((option: DropdownOption) => option.value === selected),
      )
    }) as ComputedRef<number[]>

    const selectedOptions = computed({
      get: () => {
        return filteredOptions.value.filter((_, index) => selectedOptionIndexes.value?.includes(index))
      },
      set: (option: DropdownOption | DropdownOption[]) => {
        let value = (option as DropdownOption)?.value

        // deselect if already in selected
        if (state.selected.includes(value)) {
          state.selected = state.selected.filter((selected: unknown) => selected !== value)
        } else {
          state.selected = props.multiple ? [...state.selected, value] : [value]
        }

        if (option) {
          search.value = ''
        }

        const result = props.multiple ? state.selected.filter((s: unknown) => !!s) : state.selected[0] || null
        model.value = result as unknown as string | number | boolean | object | Array<unknown>
        emit('update:modelValue', result)

        if (!props.multiple && !search.value) {
          state.isOpen = false
          emit('blur')
        }
      },
    }) as WritableComputedRef<DropdownOption | DropdownOption[] | undefined>

    const dropdownLabel = computed(() => {
      return Array.isArray(selectedOptions.value) && selectedOptions.value?.length
        ? selectedOptions.value?.map((o) => o.label).join(', ')
        : props.placeholder
    })

    /**
     * Keyboard navigation stuff still a bit janky
     */

    const selectNext = () => {
      const index = focusedOptionIndex.value
      if (index < filteredOptions.value.length - 1) {
        focusedOptionIndex.value++
        return
      }

      focusedOptionIndex.value = 0
    }

    const selectPrevious = () => {
      const index = focusedOptionIndex.value
      if (index >= 0) {
        focusedOptionIndex.value--
        return
      }

      focusedOptionIndex.value = filteredOptions.value.length - 1
    }

    const dropdownMenu = ref()
    const dropdownInput = ref()
    const onFocusOut = (e: PointerEvent) => {
      if (e.composedPath().includes(dropdownMenu.value)) return
      if (e.composedPath().includes(dropdownInput.value)) return
      focusedOptionIndex.value = -1
      state.isOpen = false
      emit('blur')
    }

    watch(
      () => state.isOpen,
      (isOpen) => {
        if (isOpen) {
          document.body.addEventListener('mousedown', onFocusOut)
        } else {
          document.body.removeEventListener('mousedown', onFocusOut)
        }
      },
    )

    const onEnter = () => {
      if (focusedOptionIndex.value === -1) {
        state.isOpen = false
        searchRef.value.blur()
        return
      }

      selectedOptions.value = filteredOptions.value[focusedOptionIndex.value]
      focusedOptionIndex.value = -1
    }

    expose({
      state,
      focusedOptionIndex,
      onFocusOut,
      searchRef,
    })

    return {
      dropdownLabel,
      state,
      search,
      filteredOptions,
      selectedOptionIndexes,
      selectedOptions,
      selectNext,
      selectPrevious,
      searchRef,
      onFocusOut,
      focusedOptionIndex,
      onEnter,
      dropdownMenu,
      dropdownInput,
      errorMessage,
      model,
    }
  },
})
</script>
