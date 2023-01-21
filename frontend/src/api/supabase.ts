import { createClient } from '@supabase/supabase-js'
import ApiClient from './apiClient'

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL || 'http://localhost:8000',
  (import.meta.env.VITE_SUPABASE_ANON as string) || 'jwt') // TODO: add dev jwt

export default new ApiClient(supabase)
