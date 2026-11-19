import { useState } from 'react'
import './App.css'

const programs = [
  {
    number: '01',
    icon: 'book',
    title: 'Éducation pour tous',
    description:
      'Des kits scolaires et un accompagnement pour aider chaque enfant à apprendre dans de bonnes conditions.',
    color: 'peach',
    link: '#contact',
  },
  {
    number: '02',
    icon: 'laptop',
    title: 'Avenir numérique',
    description:
      'Des ateliers créatifs pour découvrir l’informatique et imaginer les projets numériques de demain.',
    color: 'mint',
    link: '#contact',
  },
  {
    number: '03',
    icon: 'hands',
    title: 'Familles soutenues',
    description:
      'Un appui concret aux parents pour mieux préparer la rentrée et répondre aux besoins essentiels.',
    color: 'lavender',
    link: '#contact',
  },
]

const partners = [
  { name: 'UNICEF', href: 'https://www.unicef.org/' },
  {
    name: 'Ministère des Affaires sociales et du Travail',
    href: 'https://mast.gouv.ht/',
  },
  { name: 'ONU', href: 'https://www.un.org/fr/' },
]

const currentYear = new Date().getFullYear()

function Icon({ name, size = 22 }) {
  const paths = {
    arrow: <path d="M5 12h14m-6-6 6 6-6 6" />,
    book: (
      <>
        <path d="M12 7v14" />
        <path d="M3 18V5a2 2 0 0 1 2-2h3a4 4 0 0 1 4 4 4 4 0 0 1 4-4h3a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2h-4a3 3 0 0 1-3-3 3 3 0 0 1-3 3H5a2 2 0 0 1-2-2Z" />
      </>
    ),
    laptop: (
      <>
        <rect x="3" y="4" width="18" height="13" rx="2" />
        <path d="M2 20h20M8 20h8" />
      </>
    ),
    hands: (
      <>
        <path d="M12 21v-7m0 0-3.5-3.5a2.1 2.1 0 0 1 3-3L12 8l.5-.5a2.1 2.1 0 0 1 3 3L12 14Z" />
        <path d="m8.5 11.5-2-2a2.1 2.1 0 0 0-3 3l5.2 5.2A5 5 0 0 0 12 19h2a5 5 0 0 0 3.5-1.5l4-4a2.1 2.1 0 0 0-3-3l-2 2" />
      </>
    ),
    heart: (
      <path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8l1.1 1.1L12 21l7.8-7.5 1.1-1.1a5.5 5.5 0 0 0-.1-7.8Z" />
    ),
    pin: (
      <>
        <path d="M20 10c0 5-8 12-8 12S4 15 4 10a8 8 0 1 1 16 0Z" />
        <circle cx="12" cy="10" r="2.5" />
      </>
    ),
    menu: (
      <>
        <path d="M4 7h16M4 12h16M4 17h16" />
      </>
    ),
    close: <path d="m18 6-12 12M6 6l12 12" />,
  }

  return (
    <svg
      aria-hidden="true"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {paths[name]}
    </svg>
  )
}

function App() {
  const [menuOpen, setMenuOpen] = useState(false)

  const closeMenu = () => setMenuOpen(false)

  return (
    <>
      <div className="announcement">
        <span className="announcement-dot" />
        Depuis 2008, nous faisons grandir les possibles à Port-au-Prince.
        <a href="#mission">
          Notre mission <Icon name="arrow" size={15} />
        </a>
      </div>

      <header className="site-header">
        <a className="brand" href="#accueil" aria-label="FAFEDAA, accueil">
          <img src="/logo_fafedaa.jpeg" alt="" className="brand-logo" />
          <span className="brand-name">
            FAFEDAA
            <small>Un avenir assuré</small>
          </span>
        </a>

        <button
          type="button"
          className="menu-toggle"
          aria-label={menuOpen ? 'Fermer le menu' : 'Ouvrir le menu'}
          aria-expanded={menuOpen}
          onClick={() => setMenuOpen(!menuOpen)}
        >
          <Icon name={menuOpen ? 'close' : 'menu'} />
        </button>

        <nav className={menuOpen ? 'main-nav is-open' : 'main-nav'}>
          <a href="#mission" onClick={closeMenu}>Notre mission</a>
          <a href="#actions" onClick={closeMenu}>Nos actions</a>
          <a href="#histoire" onClick={closeMenu}>Qui sommes-nous</a>
          <a href="#contact" onClick={closeMenu}>Contact</a>
          <a className="nav-cta" href="#contact" onClick={closeMenu}>
            Nous soutenir <Icon name="arrow" size={17} />
          </a>
        </nav>
      </header>

      <main>
        <section className="hero-section" id="accueil">
          <div className="hero-copy">
            <div className="eyebrow"><span /> ENSEMBLE, TOUT DEVIENT POSSIBLE</div>
            <h1>
              Chaque enfant
              <br />
              mérite un <span>avenir</span>
              <br />
              qui lui ressemble.
            </h1>
            <p className="hero-description">
              Aux côtés des enfants et de leurs familles, nous ouvrons les
              portes de l’éducation, du numérique et de nouvelles espérances.
            </p>
            <div className="hero-actions">
              <a className="button button-dark" href="#actions">
                Découvrir nos actions <Icon name="arrow" size={18} />
              </a>
              <a className="text-link" href="#histoire">
                Notre histoire <span className="play-icon">▶</span>
              </a>
            </div>
            <div className="hero-note">
              <div className="avatar-stack" aria-hidden="true">
                <span>J</span><span>M</span><span>A</span>
              </div>
              <p><strong>Au cœur de Delmas 75</strong><br />Une communauté qui avance ensemble</p>
            </div>
          </div>

          <div className="hero-visual">
            <img
              src="https://images.unsplash.com/photo-1503676260728-1c00da094a0b?auto=format&fit=crop&w=1200&q=85"
              alt="Des enfants réunis autour d’une activité éducative"
              className="hero-image"
            />
            <div className="image-wash" />
            <div className="hero-sticker">
              <Icon name="heart" size={20} />
              <span>Grandir<br />ensemble</span>
            </div>
            <div className="impact-card">
              <span className="impact-mark">✳</span>
              <div><strong>Depuis 2008</strong><small>au service des familles</small></div>
            </div>
            <div className="image-caption">
              <span className="caption-dot" />
              <span>Port-au-Prince, Haïti</span>
            </div>
          </div>
          <div className="hero-bottom-line">
            <span>ÉDUCATION</span><i /><span>NUMÉRIQUE</span><i /><span>SOLIDARITÉ</span>
          </div>
        </section>

        <section className="mission-section section-wrap" id="mission">
          <div className="section-heading">
            <div>
              <div className="eyebrow"><span /> CE QUI NOUS ANIME</div>
              <h2>Un coup de pouce aujourd’hui.<br /><span>Des possibilités pour demain.</span></h2>
            </div>
            <p>
              Nous croyons qu’avec les bons outils et un peu de soutien,
              chaque enfant peut révéler son potentiel.
            </p>
          </div>

          <div className="program-grid" id="actions">
            {programs.map((program) => (
              <article className={`program-card ${program.color}`} key={program.number}>
                <div className="card-topline">
                  <span className="program-icon"><Icon name={program.icon} size={24} /></span>
                  <span className="program-number">{program.number}</span>
                </div>
                <h3>{program.title}</h3>
                <p>{program.description}</p>
                <a href={program.link} aria-label={`En savoir plus : ${program.title}`}>
                  En savoir plus <Icon name="arrow" size={17} />
                </a>
              </article>
            ))}
          </div>
        </section>

        <section className="story-section" id="histoire">
          <div className="story-inner section-wrap">
            <div className="story-art">
              <img
                src="https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&w=1000&q=85"
                alt="Une bénévole accompagne un enfant dans son apprentissage"
                loading="lazy"
              />
              <div className="story-badge"><span>✳</span> Un engagement<br />depuis le 13 mars 2008</div>
            </div>
            <div className="story-copy">
              <div className="eyebrow"><span /> UNE HISTOIRE DE CŒUR</div>
              <h2>Parce qu’aucun<br />rêve ne devrait<br /><span>s’arrêter faute de moyens.</span></h2>
              <p>
                Fondée le 13 mars 2008, FAFEDAA est née d’une conviction :
                investir dans les enfants et soutenir leurs parents, c’est
                investir dans l’avenir de toute une communauté.
              </p>
              <p>
                Portée notamment par le Pasteur Jean Presnor Azor, notre
                fraternité agit avec proximité, respect et solidarité.
              </p>
              <a className="button button-outline" href="#contact">
                Faire connaissance <Icon name="arrow" size={18} />
              </a>
            </div>
          </div>
        </section>

        <section className="support-section" id="contact">
          <div className="support-inner section-wrap">
            <div className="support-icon"><Icon name="heart" size={25} /></div>
            <div>
              <div className="eyebrow">CHAQUE GESTE COMPTE</div>
              <h2>Et si on construisait la suite ensemble ?</h2>
              <p>Un don, du temps, des fournitures ou une idée : votre soutien fait la différence.</p>
            </div>
            <a className="button button-light" href="mailto:?subject=Je%20souhaite%20soutenir%20FAFEDAA">
              Je veux aider <Icon name="arrow" size={18} />
            </a>
          </div>
        </section>
      </main>

      <footer className="site-footer">
        <div className="footer-main section-wrap">
          <div className="footer-about">
            <a className="brand footer-brand" href="#accueil">
              <img src="/logo_fafedaa.jpeg" alt="" className="brand-logo" />
              <span className="brand-name">FAFEDAA<small>Un avenir assuré</small></span>
            </a>
            <p>Fraternité d’Aide aux Familles et aux Enfants Démunis pour un Avenir Assuré.</p>
            <span className="footer-location"><Icon name="pin" size={17} /> Delmas 75, Rue Bethanie, Port-au-Prince</span>
          </div>
          <div className="footer-links">
            <h3>Explorer</h3>
            <a href="#mission">Notre mission</a>
            <a href="#actions">Nos actions</a>
            <a href="#histoire">Notre histoire</a>
            <a href="#contact">Nous contacter</a>
          </div>
          <div className="footer-links partners-links">
            <h3>Liens utiles</h3>
            {partners.map((partner) => (
              <a href={partner.href} key={partner.name} target="_blank" rel="noreferrer">
                {partner.name} <span aria-hidden="true">↗</span>
              </a>
            ))}
          </div>
        </div>
        <div className="footer-bottom section-wrap">
          <span>© {currentYear} FAFEDAA. Tous droits réservés.</span>
          <span>Fait avec <Icon name="heart" size={14} /> à Port-au-Prince</span>
        </div>
      </footer>
    </>
  )
}

export default App
