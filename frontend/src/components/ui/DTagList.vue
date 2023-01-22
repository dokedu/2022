<template>
  <div class="flex items-start gap-5">
    <DDropdown v-if="editable" ref="inputRef" v-model="input" name="tag_input" :label="label" :placeholder="placeholder"
      :options="dropdownOptions" @blur="addTag" @search="setTagValue" @keydown.enter="addTag" />
    <div class="flex flex-col">
      <label class="mb-1 text-xs text-slate-500">Aktuelle Tags</label>
      <div class="mt-2 flex flex-wrap gap-2">
        <ItemTag v-for="(tag, index) in tags" :key="tag.id" :removable="editable" @remove="removeTag(index)">
          {{ tag.name }}
        </ItemTag>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import ItemTag from './DTag.vue'
import { computed, defineComponent, onMounted, onUnmounted, ref, watch } from 'vue'
import DDropdown from './DDropdown.vue'
import { useSWRVS } from '../../api/helper'
import supabase from '../../api/supabase'
import { Tag } from '../../../../backend/test/types'
import { useStore } from '../../store/store'
import { getOrganisationId } from '../../helper/general'

export default defineComponent({
  name: 'DTagList',
  components: { DDropdown, ItemTag },
  props: {
    modelValue: {
      type: Array as () => Tag[],
      default: () => [],
    },
    editable: {
      type: Boolean,
      default: true,
    },
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
    allowCreate: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['update:modelValue', 'add'],
  setup(props, { emit }) {
    const fetchTags = () => supabase.from('tags').select('*').eq('organisation_id', getOrganisationId()).order('name', { ascending: true })
    const { data: tagsAvailable } = useSWRVS<Tag[]>(`/tags`, fetchTags(), {
      revalidateOnFocus: false,
    })

    const dropdownOptions = computed(() =>
      tagsAvailable.value
        ?.map(({ name }) => ({
          value: name,
          label: name,
        }))
        .filter(({ value }) => !tags.value?.map(({ name }) => name).includes(value)),
    )

    let tags = ref<Tag[]>(props.modelValue)
    const input = ref<string[] | string>()
    const inputRef = ref(null)
    const interval = ref()

    watch(
      props,
      () => {
        tags.value = props.modelValue
      },
      { deep: true },
    )

    const setTagValue = (value: string) => {
      input.value = value
    }

    const addTag = async () => {
      if (input.value) {
        const user = useStore().account.id

        const _tags = Array.isArray(input.value) ? input.value : input.value?.split(',')
        for (let tag of _tags) {
          if (tag.replaceAll(' ', '').length < 1) continue
          tag = tag.trim()

          const existingTag = tagsAvailable.value?.find(({ name }) => name === tag) as unknown as Tag
          /**
           * Check if we need to create tag
           */
          if (props.allowCreate && !existingTag) {
            const { data: createdTag } = await supabase
              .from('tags')
              .insert({ name: tag, created_by: user, organisation_id: getOrganisationId() })
              .single().select()
            tagsAvailable.value?.push(createdTag as unknown as Tag)
            tags.value.push(createdTag as unknown as Tag)
          }

          /**
           * Find Tag data and add it to tags
           */
          if (!tags.value?.map(({ name }) => name).includes(tag) && existingTag) {
            tags.value.push(existingTag)
          }
        }

        emit('update:modelValue', tags.value)
        input.value = []
        if (inputRef.value) {
          inputRef.value.searchRef.blur()
          inputRef.value.state.search = ''
        }
      }
    }
    const removeTag = (index: number) => {
      tags.value = tags.value.filter((t: Tag, i: number) => i !== index)
      emit('update:modelValue', tags.value)
    }

    onMounted(() => {
      if (props.editable) {
        interval.value = setInterval(() => {
          if (inputRef.value.$el && !input.value) {
            input.value = inputRef.value.$el.getElementsByTagName('input')[0].value
          }
        }, 500)
      }
    })

    onUnmounted(() => {
      clearInterval(interval.value)
    })

    return { tags, input, setTagValue, addTag, removeTag, inputRef, dropdownOptions }
  },
})
</script>
