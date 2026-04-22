# Thai Garden — Menu Site

A bilingual (Hebrew RTL / English LTR) restaurant menu for a food truck in the Galilee, deployed via GitHub Pages from this repo's root. Customers typically open it by scanning a QR at the truck, on a phone, one-handed, sometimes in sunlight. That constrains every decision: it has to be fast, legible, accessible, and feel premium.

Current state: a single ~3,900-line `index.html` with inline CSS + JS (both languages duplicated as separate blocks). A `generate_menu_docs.py` script builds `Thai_Garden_Menu_{English,Hebrew}.docx` from the HTML.

Target state: a small, professional, data-driven static site with a single source of truth for menu content. A refactor is planned — do not start it on my own; wait for me to initiate.

## Product intent

The bar is "best-in-class restaurant menu," not "functional web page." Every change should leave the site cleaner, faster, more accessible, and more on-brand than it was. Treat visual calm, typography, whitespace, motion, and micro-copy as first-class. Think like a senior product designer and a senior front-end engineer at the same time.

## Working rules

- **Bilingual parity, always.** Any menu item, price, description, category, badge, note, meta tag, `alt`/`aria-label`, or copy change on one side must be mirrored on the other *in the same change*. No one-sided edits — ever.
- **Review before commit.** Make the edits, summarise what changed, and stop. Do not stage, commit, or push unless I say "commit it" / "push it." Match the repo's terse commit message style (1–3 words) when I do ask.
- **I preview locally first.** After changes, give me a short "what to verify" list: which tab, which section, Hebrew *and* English, dark *and* light, and a narrow mobile width (~375px). Don't claim "done" from the diff alone.
- **Images: I drop them.** Pattern is `images/wPT_<Hebrew-name>.jpg`. When a new dish needs an image you don't yet see in `images/`, tell me the exact expected filename and wire the markup for it — don't block on the file.
- **`.docx` artifacts.** `index.html` is the source of truth. Only run `generate_menu_docs.py` and commit the regenerated docs when I ask.
- **Don't touch Hebrew copy stylistically.** Silently fix clear typos; surface any rewrite or tone change for my approval before applying.

## Quality bar (apply on every edit, no exceptions)

- **Semantics & a11y.** Use real landmarks (`header`, `nav`, `main`, `section`). Each language block must have correct `lang` and `dir`. `alt` and `aria-label` must be in the *same language as the block they live in*. Visible keyboard focus, ESC/overlay dismissal, and roving/tab order for the tab nav and image modal. No colour-only signalling (e.g. spicy 🌶 should also be text/icon, not just red).
- **RTL/LTR correctness.** Prefer logical properties: `margin-inline`, `padding-inline`, `inset-inline-*`, `text-align: start/end`. Avoid hardcoded `left`/`right` unless genuinely direction-agnostic. Test both directions after any layout change.
- **Performance.** Images: `loading="lazy"`, `decoding="async"`, explicit `width`/`height` to kill CLS, WebP where possible, `srcset` for hero/large dish photos. Keep the critical render path tiny. No render-blocking third-party scripts. Target a Lighthouse mobile score of 95+ on Performance, A11y, Best Practices, SEO.
- **Design tokens.** Honour the CSS custom properties already defined in `:root` / `body.dark-mode` (`--text-accent`, `--category-bg`, `--price-bg`, …). Never introduce ad-hoc hex values — extend the token set instead. Same for spacing/radii when we extract them.
- **Micro-interactions.** Transitions should be subtle (150–250ms, ease-out), reduced-motion aware (`prefers-reduced-motion`). No bounce/parallax unless deliberately designed.
- **SEO / share.** Keep `<title>`, `<meta description>`, OG/Twitter tags accurate in both languages. Add `schema.org/Restaurant` + `Menu` JSON-LD when we refactor — it materially helps Google surfacing for a menu page.
- **No sprawl.** If the same inline `style=""` repeats 3+ times, lift it to a class. If a block of HTML repeats between HE/EN with only text differences, flag it as a refactor candidate — don't fix it ad hoc inside the monolith.

## Architecture direction (for the refactor, when I start it)

Keep day-to-day edits compatible with this target so the eventual migration is mechanical, not archaeological.

- **Single source of truth**: `menu.json` (or `.ts`) shaped like:
  ```ts
  {
    categories: [{
      id, slug, icon,
      name: { he, en },
      items: [{
        id, price, image,
        name: { he, en },
        description: { he, en },
        tags: ["spicy" | "vegan" | "gluten-free" | "new" | "chef" | ...],
        allergens?: [...]
      }]
    }]
  }
  ```
  Both languages render from one list — zero duplication.
- **Static site generator**: **Astro** is the default recommendation — content-driven, zero-JS by default, first-class i18n, trivial deploy to GitHub Pages via Actions. 11ty is acceptable if we want pure templating with no JS runtime. Pick at refactor time; don't pre-commit.
- **Styles**: split into `tokens.css` (colours, spacing, radii, typography scale) → `base.css` (reset, body, typography) → `components/` (header, tabs, category, menu-item, price, badge, modal, quick-nav, welcome). BEM-ish or the SSG's native CSS scoping — pick one and stay consistent.
- **JS**: small, modern, no framework. Language toggle, theme toggle (persist to `localStorage`, respect `prefers-color-scheme` on first visit), tab switching, anchor nav, image lightbox. Progressive enhancement — the menu must render and be readable with JS disabled.
- **PWA-lite (post-refactor)**: installable, offline-capable menu via a minimal service worker. Huge UX win at the truck with flaky cell service.
- **Deployment**: GitHub Actions builds on push to `main` and publishes to Pages. Until the refactor ships, the repo root must keep serving `index.html` directly.

## Don't

- Don't start the refactor, add a build step, or introduce npm dependencies without me asking.
- Don't split `index.html` piecemeal — partial refactors leave the codebase worse than either end state.
- Don't rename, move, or delete anything in `images/` — I curate those.
- Don't add analytics, tracking, cookie banners, or third-party widgets.
- Don't add generated-by-AI footers, watermarks, or marketing copy I didn't ask for.
- Don't amend or force-push; don't bypass hooks.
