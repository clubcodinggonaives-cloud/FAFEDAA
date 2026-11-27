import { isSupabaseConfigured } from '../lib/supabase'

export class BackendConfigurationError extends Error {
  constructor() {
    super('Le service de données n’est pas configuré.')
    this.name = 'BackendConfigurationError'
  }
}

export function requireSupabaseConfiguration() {
  if (!isSupabaseConfigured) throw new BackendConfigurationError()
}
