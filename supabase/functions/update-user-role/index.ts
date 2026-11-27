import { authorizeStaff, corsHeaders, isStaffRole, json } from '../_shared/staff-auth.ts'

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json(405, { error: 'method_not_allowed' })

  try {
    const actor = await authorizeStaff(request)
    if (!actor) return json(401, { error: 'unauthorized' })

    const body = await request.json().catch(() => null)
    const userId = body?.user_id
    const role = body?.role
    const action = body?.action
    if (typeof userId !== 'string' || !UUID_PATTERN.test(userId) || !isStaffRole(role) ||
        role === 'super_admin' || typeof action !== 'string' || !['grant', 'revoke'].includes(action)) {
      return json(400, { error: 'invalid_role_change' })
    }
    if (userId === actor.user.id) return json(403, { error: 'forbidden' })

    const isSuperAdmin = actor.roles.has('super_admin')
    const isAdmin = actor.roles.has('admin')
    const canManage = isSuperAdmin || (isAdmin && ['program_manager', 'social_worker', 'content_editor'].includes(role))
    if (!canManage) return json(403, { error: 'forbidden' })

    const { data: target, error: targetError } = await actor.admin
      .from('profiles')
      .select('id')
      .eq('id', userId)
      .maybeSingle()
    if (targetError || !target) return json(404, { error: 'staff_not_found' })

    const { data: roleRecord, error: roleError } = await actor.admin
      .from('roles')
      .select('id')
      .eq('name', role)
      .single()
    if (roleError || !roleRecord) return json(400, { error: 'invalid_role_change' })

    const { data: changed, error: changeError } = await actor.admin.rpc('change_staff_role', {
      _actor_id: actor.user.id,
      _target_profile_id: userId,
      _role_id: roleRecord.id,
      _action: action,
    })
    if (changeError) return json(403, { error: 'role_change_failed' })
    return json(200, { updated: Boolean(changed) })
  } catch {
    return json(500, { error: 'role_change_failed' })
  }
})
