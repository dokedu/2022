import { generateHTML } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import { generateText } from '@tiptap/vue-3'

export const renderEntryBody = (body: JSON) => generateHTML(body, [StarterKit])
export const renderEntryBodyText = (body: JSON) => generateText(body, [StarterKit])
