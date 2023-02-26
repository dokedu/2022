<template>
  <editor-content :editor="editor" data-cy="entry-description" />
  <small v-if="errorMessage" class="mt-1 text-red-400">{{ errorMessage }}</small>
</template>

<script lang="ts" setup>
import { Editor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import { useField } from 'vee-validate'
import { onBeforeUnmount, onMounted, ref, watch, toRef } from 'vue'

const props = defineProps({
  name: {
    type: String,
    default: '',
  },
  modelValue: {
    type: [Object, String],
    default: () => ({}),
  },
})
const emit = defineEmits(['update:modelValue'])

const name = toRef(props, 'name')

const { value: model, errorMessage } = useField(name, undefined, {
  initialValue: toRef(props, 'modelValue'),
  validateOnMount: false,
})

const updateModel = () => {
  model.value = editor.value.getJSON()
}

watch(
  () => props.modelValue,
  (value) => {
    const isSame = JSON.stringify(editor.value.getJSON()) === JSON.stringify(value)
    //updateModel()
    if (isSame) return

    editor.value.commands.setContent(value, false)
    updateModel()
  },
)

const editor = ref()
onMounted(() => {
  editor.value = new Editor({
    extensions: [StarterKit],
    content: props.modelValue,
    onUpdate: () => {
      emit('update:modelValue', editor.value.getJSON())
    },
  })
})

onBeforeUnmount(() => {
  editor.value.destroy()
})

</script>

<style>
div.ProseMirror {
  background-color: #fff;
  border-radius: 5px;
  border: 1px solid rgb(209, 213, 219);
  padding: 12px;
  font-size: 14px;
  min-height: 100px;
}

div.ProseMirror:focus {
  outline: none;
}

div.ProseMirror p {
  margin: 0;
  font-size: 16px;
}

div.ProseMirror p.is-editor-empty:first-child::before {
  content: attr(data-placeholder);
  float: left;
  color: #adb5bd;
  pointer-events: none;
  height: 0;
}
</style>
