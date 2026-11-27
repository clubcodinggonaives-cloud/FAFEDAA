import { authorizeStaff, corsHeaders, isStaffRole, json, requiredEnv } from '../_shared/staff-auth.ts'

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json(405, { error: 'method_not_allowed' })

  try {
    const actor = await authorizeStaff(request)
    if (!actor) return json(401, { error: 'unauthorized' })

    const body = await request.json().catch(() => null)
    const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : ''
    const displayName = typeof body?.display_name === 'string' ? body.display_name.trim() : ''
    const language = body?.preferred_language
    const role = body?.role

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254 || !displayName || displayName.length > 100) {
      return json(400, { error: 'invalid_invitation' })
    }
    if (!isStaffRole(role) || role === 'super_admin' || typeof language !== 'string' ||
        !['fr', 'ht', 'en'].includes(language)) {
      return json(400, { error: 'invalid_invitation' })
    }

    const canInvite = actor.roles.has('super_admin') || actor.roles.has('admin')
    const canGrantRole = actor.roles.has('super_admin') ||
      (actor.roles.has('admin') && ['program_manager', 'social_worker', 'content_editor'].includes(role))
    if (!canInvite || !canGrantRole) return json(403, { error: 'forbidden' })

    const { data: roleRecord, error: roleLookupError } = await actor.admin
      .from('roles')
      .select('id')
      .eq('name', role)
      .single()
    if (roleLookupError || !roleRecord) return json(500, { error: 'invitation_failed' })

    const redirectTo = requiredEnv('STAFF_INVITE_REDIRECT_URL')
    const { data: invited, error: inviteError } = await actor.admin.auth.admin.inviteUserByEmail(email, {
      data: { display_name: displayName, preferred_language: language },
      redirectTo,
    })
    const userId = invited.user?.id
    if (inviteError || !userId) return json(400, { error: 'invitation_failed' })

    const { error: provisioningError } = await actor.admin.rpc('provision_invited_staff', {
      _actor_id: actor.user.id,
      _user_id: userId,
      _display_name: displayName,
      _preferred_language: language,
      _role_id: roleRecord.id,
    })
    if (provisioningError) {
      await actor.admin.auth.admin.deleteUser(userId)
      return json(500, { error: 'invitation_failed' })
    }

    return json(201, { invited: true })
  } catch {
    return json(500, { error: 'invitation_failed' })
  }
})
