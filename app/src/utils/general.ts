import { EntryFile } from '../../../backend/test/types';
import supabase from '../api/supabase'

export const downloadFile = async (file: { id: string; file_bucket_id: string; file_name: string }) => {
  const { data, error } = await supabase.storage.from(file.file_bucket_id).download(file.file_name)
  if (error) return

  await downloadItem(data, file.file_name.split('/')[file.file_name.split('/').length - 1].slice(22))
}
const downloadItem = async (blobData: any, label: string) => {
  const blob = new Blob([blobData])
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = label
  link.click()
  URL.revokeObjectURL(link.href)
}

export const previewImage = async (file: EntryFile) => {
  return (await supabase
    .storage
    .from(file.file_bucket_id)
    .createSignedUrl(file.file_name, 60, {
      transform: {
        width: 300,
        height: 200,
      }
    })).data?.signedUrl
}

/**
 * since using the Pinia store is too slow and has a minimal delay, we use
 * this function since it is faster and guarantees that the data is loaded
 * synchronously, which is important so when we do api queries in vue with
 * SWRV which doesn't wait for the watch function in App.vue to have loaded
 * the data from the store and distributed everywhere, we use this workaround
 */
export const getOrganisationId = () => {
  return localStorage.getItem('organisationId')
}

export function truncateString(str: string, num: number) {
  if (str.length > num) {
    return str.slice(0, num) + '...'
  } else {
    return str
  }
}
