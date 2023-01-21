import PageModal, { PageModalProps } from '../components/ui/DConfirmModal.vue'
import { createApp } from 'vue'

export function createModal(props: PageModalProps) {
  return new Promise((resolve) => {
    const modal = createApp(
      {
        ...PageModal,
        unmounted() {
          // eslint-disable-next-line @typescript-eslint/ban-ts-comment
          //@ts-ignore
          window.headless_ui_keep_open = false
        },
      },
      {
        ...props,
        onConfirm() {
          resolve(true)
          modal.unmount()
        },
        onCancel() {
          resolve(false)
          modal.unmount()
        },
      },
    )

    /* ToDo:
        there is currently a issue in headless-ui which doesn't allow us to programmatically spawn the modal while another Dialog is open,
        without breaking some things.  I found a workaround by setting the initial-focus of the first opened Dialog to document.activeElement.
        and then preventing the first dialog from closing while the second one is open

         https://github.com/tailwindlabs/headlessui/issues/825
     */
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    //@ts-ignore
    if (window) window.headless_ui_keep_open = true
    modal.mount(document.createElement('div'))
  })
}
