import { createClient, type SupabaseClient, type User } from 'npm:@supabase/supabase-js@2'

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

export const roleNames = ['super_admin', 'admin', 'program_manager', 'social_worker', 'content_editor'] as const
export type StaffRole = (typeof roleNames)[number]

export function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

export function requiredEnv(name: string) {
  const value = Deno.env.get(name)
  if (!value) throw new Error(`Missing server configuration: ${name}`)
  return value
}

export type AuthorizedStaff = {
  user: User
  roles: Set<string>
  admin: SupabaseClient
}

export async function authorizeStaff(request: Request): Promise<AuthorizedStaff | null> {
  const authorization = request.headers.get('Authorization')
  const token = authorization?.match(/^Bearer\s+(.+)$/i)?.[1]
  if (!token) return null

  const url = requiredEnv('SUPABASE_URL')
  const publicKey = Deno.env.get('SUPABASE_PUBLISHABLE_KEY') ?? requiredEnv('SUPABASE_ANON_KEY')
  const secretKey = Deno.env.get('SUPABASE_SECRET_KEY') ?? requiredEnv('SUPABASE_SERVICE_ROLE_KEY')
  const userClient = createClient(url, publicKey, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
  })
  const { data: userData, error: userError } = await userClient.auth.getUser(token)
  if (userError || !userData.user) return null

  const admin = createClient(url, secretKey, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
  })
  const { data: profile, error: profileError } = await admin
    .from('profiles')
    .select('is_active')
    .eq('id', userData.user.id)
    .maybeSingle()
  if (profileError || !profile?.is_active) return null

  const { data: assignments, error: roleError } = await admin
    .from('profile_roles')
    .select('roles(name)')
    .eq('profile_id', userData.user.id)
  if (roleError) return null

  const roles = new Set<string>()
  for (const assignment of assignments ?? []) {
    const relation = assignment.roles
    const names = Array.isArray(relation) ? relation : [relation]
    for (const value of names) {
      if (value && typeof value === 'object' && 'name' in value && typeof value.name === 'string') {
        roles.add(value.name)
      }
    }
  }

  return { user: userData.user, roles, admin }
}

export function isStaffRole(value: unknown): value is StaffRole {
  return typeof value === 'string' && roleNames.includes(value as StaffRole)
}
