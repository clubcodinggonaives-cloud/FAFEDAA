import { useEffect, useState } from 'react'
import { isSupabaseConfigured, supabase } from './lib/supabase'
import './StaffPortal.css'

const copy = {
  fr: {
    eyebrow: 'ESPACE DU PERSONNEL', title: 'Connexion du personnel', intro: 'Accès réservé aux membres du personnel invités par FAFEDAA.',
    email: 'Adresse courriel', password: 'Mot de passe', signIn: 'Se connecter', forgot: 'Mot de passe oublié ?',
    sendReset: 'Envoyer le lien de réinitialisation', back: 'Retour à la connexion', resetTitle: 'Choisir un nouveau mot de passe', newPassword: 'Nouveau mot de passe', updatePassword: 'Mettre à jour le mot de passe',
    loading: 'Vérification de votre accès…', noConfig: 'Le service de connexion n’est pas configuré.', denied: 'Ce compte n’a pas accès à l’espace du personnel. Contactez un administrateur FAFEDAA.',
    genericError: 'La demande n’a pas abouti. Vérifiez vos informations ou réessayez plus tard.', resetSent: 'Si cette adresse correspond à un compte, un lien de réinitialisation sera envoyé.', passwordChanged: 'Mot de passe mis à jour.',
    welcome: 'Bonjour', role: 'Rôle(s)', logout: 'Se déconnecter', dashboard: 'Votre session est active. Les outils de gestion seront disponibles après leur déploiement.',
  },
  ht: {
    eyebrow: 'ESPAS PÈSONÈL LA', title: 'Konekte pou pèsonèl la', intro: 'Se sèlman manm pèsonèl FAFEDAA envite ki ka antre.',
    email: 'Adrès imèl', password: 'Modpas', signIn: 'Konekte', forgot: 'Ou bliye modpas la?',
    sendReset: 'Voye lyen pou chanje modpas la', back: 'Retounen nan koneksyon', resetTitle: 'Chwazi yon nouvo modpas', newPassword: 'Nouvo modpas', updatePassword: 'Mete modpas la ajou',
    loading: 'N ap verifye aksè ou…', noConfig: 'Sèvis koneksyon an poko konfigire.', denied: 'Kont sa a pa gen aksè nan espas pèsonèl la. Kontakte administratè FAFEDAA.',
    genericError: 'Demann lan pa reyisi. Verifye enfòmasyon yo oswa eseye ankò pita.', resetSent: 'Si adrès sa a asosye ak yon kont, y ap voye yon lyen pou chanje modpas la.', passwordChanged: 'Modpas la ajou.',
    welcome: 'Bonjou', role: 'Wòl', logout: 'Dekonekte', dashboard: 'Sesyon ou aktif. Zouti jesyon yo ap disponib lè yo fin deplwaye.',
  },
  en: {
    eyebrow: 'STAFF AREA', title: 'Staff sign in', intro: 'Access is limited to FAFEDAA staff who have been invited.',
    email: 'Email address', password: 'Password', signIn: 'Sign in', forgot: 'Forgot password?',
    sendReset: 'Send reset link', back: 'Back to sign in', resetTitle: 'Choose a new password', newPassword: 'New password', updatePassword: 'Update password',
    loading: 'Checking your access…', noConfig: 'The sign-in service is not configured.', denied: 'This account does not have access to the staff area. Contact a FAFEDAA administrator.',
    genericError: 'The request could not be completed. Check your details or try again later.', resetSent: 'If this address belongs to an account, a reset link will be sent.', passwordChanged: 'Password updated.',
    welcome: 'Hello', role: 'Role(s)', logout: 'Sign out', dashboard: 'Your session is active. Management tools will be available after they are deployed.',
  },
}

const roleLabels = {
  super_admin: 'Super administrateur', admin: 'Administrateur', program_manager: 'Responsable de programme',
  social_worker: 'Agent social', content_editor: 'Éditeur de contenu',
}

export default function StaffPortal({ language = 'fr' }) {
  const t = copy[language] || copy.fr
  const [session, setSession] = useState(null)
  const [access, setAccess] = useState({ token: null, status: 'idle', profile: null, roles: [] })
  const [authReady, setAuthReady] = useState(!isSupabaseConfigured)
  const [recoveryMode, setRecoveryMode] = useState(false)
  const [view, setView] = useState('sign-in')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    if (!supabase) {
      return
    }
    let active = true
    supabase.auth.getSession().then(({ data, error: sessionError }) => {
      if (!active) return
      if (sessionError) setError(t.genericError)
      setSession(data.session)
      setAuthReady(true)
    }).catch(() => {
      if (!active) return
      setError(t.genericError)
      setAuthReady(true)
    })
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, nextSession) => {
      setSession(nextSession)
      if (event === 'PASSWORD_RECOVERY') setRecoveryMode(true)
    })
    return () => {
      active = false
      subscription.unsubscribe()
    }
  }, [t.genericError])

  useEffect(() => {
    if (!authReady) return
    if (!session || !supabase) return

    let active = true
    const verifyStaff = async () => {
      const { data: staffProfile, error: profileError } = await supabase
        .from('profiles')
        .select('display_name,is_active')
        .eq('id', session.user.id)
        .maybeSingle()
      if (profileError || !staffProfile?.is_active) throw new Error('staff_access_denied')

      const { data: assignments, error: assignmentsError } = await supabase
        .from('profile_roles')
        .select('role_id')
        .eq('profile_id', session.user.id)
      if (assignmentsError || !assignments?.length) throw new Error('staff_access_denied')

      const { data: roleRows, error: rolesError } = await supabase
        .from('roles')
        .select('name')
        .in('id', assignments.map((assignment) => assignment.role_id))
      if (rolesError || !roleRows?.length) throw new Error('staff_access_denied')
      return { profile: staffProfile, roles: roleRows.map((row) => row.name) }
    }

    verifyStaff().then((staff) => {
      if (!active) return
      setAccess({ token: session.access_token, status: 'ready', profile: staff.profile, roles: staff.roles })
      setError('')
    }).catch(async () => {
      if (!active) return
      setAccess({ token: session.access_token, status: 'denied', profile: null, roles: [] })
      setError(t.denied)
      await supabase.auth.signOut()
    })
    return () => { active = false }
  }, [authReady, session, t.denied])

  const submitSignIn = async (event) => {
    event.preventDefault()
    if (!supabase) return
    setBusy(true); setError(''); setNotice('')
    const { error: signInError } = await supabase.auth.signInWithPassword({ email, password })
    if (signInError) setError(t.genericError)
    setBusy(false)
  }

  const submitResetRequest = async (event) => {
    event.preventDefault()
    if (!supabase) return
    setBusy(true); setError(''); setNotice('')
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/dashboard`,
    })
    if (resetError) setError(t.genericError)
    else setNotice(t.resetSent)
    setBusy(false)
  }

  const submitNewPassword = async (event) => {
    event.preventDefault()
    if (!supabase) return
    setBusy(true); setError(''); setNotice('')
    const { error: updateError } = await supabase.auth.updateUser({ password: newPassword })
    if (updateError) setError(t.genericError)
    else { setNotice(t.passwordChanged); setRecoveryMode(false); setNewPassword('') }
    setBusy(false)
  }

  const signOut = async () => {
    if (!supabase) return
    setBusy(true)
    const { error: signOutError } = await supabase.auth.signOut()
    if (signOutError) setError(t.genericError)
    setBusy(false)
  }

  const loading = !authReady || (session && !recoveryMode && access.token !== session.access_token)

  return <section className="staff-portal section-wrap">
    <div className="staff-portal-card">
      <div className="eyebrow"><span />{t.eyebrow}</div>
      {!isSupabaseConfigured && <><h1>{t.title}</h1><p role="alert" className="staff-message is-error">{t.noConfig}</p></>}
      {isSupabaseConfigured && loading && <p className="staff-loading" role="status">{t.loading}</p>}
      {isSupabaseConfigured && !loading && !session && <>
        <h1>{view === 'reset' ? t.resetTitle : t.title}</h1><p className="staff-intro">{t.intro}</p>
        {view === 'reset' ? <form onSubmit={submitResetRequest} className="staff-form">
          <label>{t.email}<input type="email" autoComplete="email" value={email} onChange={(event) => setEmail(event.target.value)} required /></label>
          <button className="button button-dark" disabled={busy}>{busy ? t.loading : t.sendReset}</button>
          <button type="button" className="staff-text-button" onClick={() => { setView('sign-in'); setError(''); setNotice('') }}>{t.back}</button>
        </form> : <form onSubmit={submitSignIn} className="staff-form">
          <label>{t.email}<input type="email" autoComplete="username" value={email} onChange={(event) => setEmail(event.target.value)} required /></label>
          <label>{t.password}<input type="password" autoComplete="current-password" value={password} onChange={(event) => setPassword(event.target.value)} required /></label>
          <button className="button button-dark" disabled={busy}>{busy ? t.loading : t.signIn}</button>
          <button type="button" className="staff-text-button" onClick={() => { setView('reset'); setError(''); setNotice('') }}>{t.forgot}</button>
        </form>}
      </>}
      {isSupabaseConfigured && !loading && session && recoveryMode && <>
        <h1>{t.resetTitle}</h1>
        <form onSubmit={submitNewPassword} className="staff-form">
          <label>{t.newPassword}<input type="password" autoComplete="new-password" minLength="8" value={newPassword} onChange={(event) => setNewPassword(event.target.value)} required /></label>
          <button className="button button-dark" disabled={busy}>{busy ? t.loading : t.updatePassword}</button>
        </form>
      </>}
      {isSupabaseConfigured && !loading && session && !recoveryMode && access.status === 'ready' && access.profile && <div className="staff-home">
        <h1>{t.welcome}, {access.profile.display_name}</h1>
        <p><strong>{t.role} :</strong> {access.roles.map((role) => roleLabels[role] || role).join(', ')}</p>
        <p>{t.dashboard}</p>
        <button type="button" className="button button-outline" onClick={signOut} disabled={busy}>{t.logout}</button>
      </div>}
      {error && <p role="alert" className="staff-message is-error">{error}</p>}
      {notice && <p role="status" className="staff-message is-success">{notice}</p>}
    </div>
  </section>
}
