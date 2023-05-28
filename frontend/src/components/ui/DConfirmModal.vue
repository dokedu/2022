<template>
  <TransitionRoot as="template" :show="open">
    <Dialog :initial-focus="cancelButtonRef" as="div" class="fixed inset-0 z-10 overflow-y-auto" @close="open = false">
      <div class="flex min-h-screen items-end justify-center px-4 pt-4 pb-20 text-center sm:block sm:p-0" data-cy="modal">
        <TransitionChild as="template" enter="ease-out duration-300" enter-from="opacity-0" enter-to="opacity-100"
          leave="ease-in duration-200" leave-from="opacity-100" leave-to="opacity-0">
          <DialogOverlay class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" />
        </TransitionChild>

        <!-- This element is to trick the browser into centering the modal contents. -->
        <span class="hidden sm:inline-block sm:h-screen sm:align-middle" aria-hidden="true">&#8203;</span>
        <TransitionChild as="template" enter="ease-out duration-300"
          enter-from="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
          enter-to="opacity-100 translate-y-0 sm:scale-100" leave="ease-in duration-200"
          leave-from="opacity-100 translate-y-0 sm:scale-100"
          leave-to="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95">
          <div
            class="inline-block transform overflow-hidden rounded-lg bg-white px-4 pt-5 pb-4 text-left align-bottom shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6 sm:align-middle">
            <div class="sm:flex sm:items-start">
              <div
                class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10">
                <component :is="icon" class="h-6 w-6 text-red-600" aria-hidden="true"></component>
              </div>
              <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                <DialogTitle as="h3" class="text-lg font-medium leading-6 text-gray-900">
                  {{ title }}
                </DialogTitle>
                <div class="mt-2">
                  <p class="text-sm text-gray-500">
                    {{ description }}
                  </p>
                </div>
              </div>
            </div>
            <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
              <button type="button" :class="confirmClasses"
                class="inline-flex w-full justify-center rounded-md border border-transparent bg-red-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 sm:ml-3 sm:w-auto sm:text-sm"
                data-cy="modal-confirm" @click="onConfirm">
                {{ confirm }}
              </button>
              <button ref="cancelButtonRef" type="button" :class="cancelClasses"
                class="mt-3 inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-base font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 sm:mt-0 sm:w-auto sm:text-sm"
                data-cy="modal-cancel" @click="onCancel">
                {{ cancel }}
              </button>
            </div>
          </div>
        </TransitionChild>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script lang="ts">
import { ref } from 'vue'
import { Dialog, DialogOverlay, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { ExclamationIcon } from '@heroicons/vue/outline'

export interface PageModalProps {
  title: string
  description: string
  confirm?: string
  cancel?: string
  confirmClasses?: string
  cancelClasses?: string
  icon?: void
}

export default {
  components: {
    Dialog,
    DialogOverlay,
    DialogTitle,
    TransitionChild,
    TransitionRoot,
    ExclamationIcon,
  },
  props: {
    icon: {
      type: Function,
      default: () => ExclamationIcon(),
    },
    title: {
      type: String,
      default: 'Some Modal Title',
    },
    description: {
      type: String,
      default: 'Some Modal Text',
    },
    confirm: {
      type: String,
      default: 'Confirm',
    },
    cancel: {
      type: String,
      default: 'Cancel',
    },
    confirmClasses: {
      type: String,
      default: '',
    },
    cancelClasses: {
      type: String,
      default: '',
    },
  },
  emits: ['cancel', 'confirm'],
  setup(props, { emit }) {
    const open = ref(true)
    const cancelButtonRef = ref(null)

    const onConfirm = () => {
      open.value = false
      emit('confirm')
    }

    const onCancel = () => {
      open.value = false
      emit('cancel')
    }

    return {
      open,
      onConfirm,
      onCancel,
      cancelButtonRef,
    }
  },
}
</script>
