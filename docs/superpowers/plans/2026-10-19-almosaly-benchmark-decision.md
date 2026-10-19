# Almosaly Benchmark — Feature Decisions + Mobile/Web Roadmap

Date: 2026-10-19 · Prepared by: PM session (owner-facing) · Status: **RATIFIED BY OWNER 2026-10-19 — decisions D1–D5 resolved (see §2)**

Subject: المصلي / Almosaly (`com.moslay` v17.0.8) — full feature recon benchmarked against قرآن يَهدي.

## Evidence

- **Almosaly (verified, device-pulled Play copy):** REA/JADX recon — pull `ev_38f94929…`, manifest `ev_16481660…`, 48,392-class census, 55 permissions. Full recon reference (in-repo): `docs/superpowers/plans/2026-10-19-almosaly-recon-reference.md` (session scratch copy also at `C:\Users\ASUS\AppData\Local\Temp\opencode\almosaly-features-recon.md`). Every feature name below is an observed manifest/class identifier or store-listing text; UX intent is marked as inference where it is one.
- **Quran Yahdi (verified at source TODAY, HEAD `1ed1af9`):** 15 features (`lib/features/`: asma, azkar, duas, hijri, home, library, notifications, prayer, qibla, quran, recitation, settings, tasbih, tracker, zakat) · 19 routes · library packs (tafsir×5, hadith) · reminders infra (`reminder_planner`/`scheduler`) · web = P1–P3 landed + W4 OG closed; P4-app-links plan queued.

## Governing principles (the "why" for every decision)

1. **Free & clean** — no ads, no subscriptions, no donations, no in-app purchases. Non-negotiable identity.
2. **No backend** — no accounts, no social, no leaderboards, no server state (Supabase excluded per AGENTS.md).
3. **Offline-first** — every feature works with zero network; online only enriches (mp3quran streaming).
4. **Privacy & Play safety** — no tracking SDKs; no sensitive permissions (silent-mode/DND, call logs).
5. **Worship dignity** — no gamification of worship (points, stars, country rankings, competitions).
6. **Dependency minimalism** — every new package needs an explicit owner grant; fewer deps beats parity.

## 1) Feature matrix

### 1.1 Prayer & Adhan
| Almosaly | Quran Yahdi today | Decision | Why |
|---|---|---|---|
| Egyptian General Authority method preset | city picker + `adhan` pkg, nearest-city | **TAKE (small)** — add EG-Authority preset | Local accuracy; `adhan` supports method presets |
| Imsak/Iftar times + إمساكية | none | **TAKE** | Core Ramadan value; pure calculation + tabular view |
| Pre-adhan reminder (dua/message before adhan) | single prayer alert | **TAKE (small)** | Reminder infra exists; one inspiration card N-min before |
| Muezzin voices | default notification sound | **TAKE — 2–3 recordings (D1 ratified)**: only freely-redistributable recordings with a citable license; system-sound fallback | Owner approved licensing 2–3 free recordings; license-first gate applies |
| Escalating Fajr alarm | none | **TAKE (small)** | Local notifications; escalating repeats |
| أوقات النهي (forbidden windows) | none | **TAKE (content)** | Static windows; trivial with adhan calc |
| Exact scheduling (boot/date-change reschedule) | reminder scheduler present | parity, no action | — |
| Auto-silence device | none | **LEAVE** | WRITE_SETTINGS/DND-policy risk; intrusive |
| Home-screen widgets | none | **TAKE (grant APPROVED: `home_widget`)** | Highest-visibility pick for a prayer app |
| Daily tasks hub (calendar tasks list) | none | **LEAVE** | Scope creep; outside identity |

### 1.2 Qibla
| 5 methods + AR mode | compass only | **TAKE sun/shadow methods; LEAVE AR** | Sun/shadow = pure math, no deps. AR = heavy deps, low payoff on target devices |
| Calibration UX/warnings | basic | **TAKE (small UX polish)** | Accuracy guardrails |

### 1.3 Quran
| Mushaf/tafsir/bookmarks | ✓ | parity | — |
| Khatma: plans + chat + group + notifications | tracker has khatma **plans** | **TAKE = ورد محسّن** (daily wird, page ranges, reminders, optional prayer-time linking) · **LEAVE chat/group** | Wird-linked-to-prayer-times is an elegant idea; chat/group = backend |
| Memorization plan (steps/repetition modes/reciter/audio) | none | **TAKE (big)** | Highest-value religious feature; fully offline; reuses recitations |
| Audio player sleep timer | mini player | **TAKE (small)** | `just_audio` supports it |
| Share ayah/dua as image | none | **TAKE (small-medium)** | Da'wah value; `share_plus` already in repo |
| Word-by-word meanings | tafsir packs | **TAKE — license-first gate (D2 ratified)**: source word-by-word data under a verified redistributable license BEFORE implementation; if no clean source → skip | Owner: "data under a proper license first" |

### 1.4 Azkar / Tasbih / Duas
| Categorized azkar + per-zikr counters | ✓ | parity | — |
| عمل اليوم والليلة (daily azkar tasks) | list only | **TAKE (content + UI)** | Structured daily worship; offline |
| Azkar search | none | **TAKE (small)** | Local search over existing content |
| Sebha settings/goals/binding | circular + goals | **TAKE (small polish)** | Persist settings; bind counter to a specific zikr |
| كنوز الأذكار (counter categories) | per-zikr counters | **ADAPT** — fold into counter goals | No new subsystem |
| Dua dashboard/awrad/audio recitations | duas screen | **TAKE partial** — daily dua card + awrad; audio gated on the same license-first rule | — |
| Social dua requests (post/amen/stats) | none | **LEAVE** | Backend + moderation; privacy |

### 1.5 Ramadan
| Qada (missed fasts) tracker | none | **TAKE** | Local drift DB; fits tracker feature |
| Fasting rules (men/women) | none | **TAKE (content pack in library)** | Library pack infra exists |
| إمساكية month view | none | **TAKE (app + web)** | Seasonal, tabular |
| Ramadan decorations | none | **ADAPT optional** — restrained seasonal accents only | Cheap delight; keep tasteful |
| Ramadan competition | none | **LEAVE** | Gamification + backend |

### 1.6 Charity / Payments / Gamification
| Goodness bank: sadqa/zakat/campaigns/payments | zakat calculator only | **LEAVE** | Payment/charity compliance, backend, outside portfolio scope |
| Fawry, e-wallets, gold subscription, free trial, in-app purchase | none | **LEAVE (hard)** | Contradicts Free-&-clean identity |
| طاعاتك stars/badges/rankings, country worship ranks, share-rewards | tracker (kept plain) | **LEAVE (hard)** | Worship dignity; no points/leaderboards |

### 1.7 Places & niche modules
| Nearest mosques + halal (HERE/Google keys inside APK) | none | **Web via OSM (D4 ratified → WW3)**; app **LEAVE for now** | Keys/quotas can't survive free-100%; OSM is free on web |
| Prayers on plane (flight tracks/athkar/alarms) | none | **LEAVE (park as future idea)** | Niche; maps+tracking complexity vs payoff |
| Mo3een Fajr (friends call each other) | none | **LEAVE** | Telephony permissions + backend matchmaking |
| Speech recognition | none | **LEAVE** | Unclear usage; mic permission |

### 1.8 Community / Account / Misc app
| Community, comments, mail, news, in-app messaging, remote config, surveys | none | **LEAVE** | Backend + moderation; not in v1.x scope |
| Extra languages (fa/ru/tr/fr) | AR/EN | **LEAVE now** | Translation/content cost; AR-first identity |
| Sign-in/sign-up/account deletion | none (no accounts) | **LEAVE** | No-backend principle; data stays local |
| Rate prompt | none | **TAKE (D5 ratified)** — polite variant only (after meaningful usage; never blocking) | Small; owner-approved |
| What's New screen | none | **ADAPT tiny (optional)** | Static changelog; cheap |
| Location onboarding multi-step | onboarding exists | parity; small polish only if observed gap | — |

### 1.9 Web (almosaly.com benchmark vs quranyahdi site)
| /mawaquit city prayer-time pages | not present | **TAKE (WW1)** | Static per-city SEO pages = free growth |
| /amsakiah | not present | **TAKE (WW1)** | Seasonal tabular page |
| Qibla tool page | not present | **TAKE (WW1)** | Bearing calculator, client-side |
| Azkar/duas/asma evergreen content pages | not present | **TAKE (WW2, generated from app packs)** | Evergreen SEO; reuse existing data |
| Live stream, favorites, khatma page, advertise, comments | not present | **LEAVE** | Backend/streaming/ads |
| 4 extra site languages | AR + EN | keep AR/EN | Scope |

## 2) Owner decisions — RATIFIED 2026-10-19

- **D1 — Adhan audio: RESOLVED (take).** License/ship 2–3 freely-redistributable adhan recordings; each asset must carry a citable license on file; system-sound fallback stays.
- **D2 — Word-by-word meanings: RESOLVED (license-first).** Proceed only after sourcing the data under a verified clean license ("صدر بيانات برخصة سليمة أولًا"); no clean source → the feature is skipped, not guessed.
- **D3 — Widgets: RESOLVED (approved).** `home_widget` grant + native config approved.
- **D4 — Web nearest-mosque map: RESOLVED (approved).** OSM/Overpass on the web (WW3).
- **D5 — In-app review prompt: RESOLVED (approved).** Polite variant only.

## 3) Mobile roadmap (proposed order — each wave gets its own executor brief)

- **R1 — License clearance research (doc-only, no code):** verify + record sources/licenses for (a) the 2–3 adhan recordings, (b) word-by-word meanings data. Output: a short license dossier. Gate for A4-audio/A5-audio and the word-by-word item.
- **A0 (already queued):** finish current app WIP → F11 close → execute **P4-app-links** (existing plan).
- **A1 — ورد وختمة محسّنة** (S): daily wird with page ranges, optional prayer-time linking, reminders, progress in tracker. Reuse tracker+khatma plans.
- **A2 — عمل اليوم والليلة + بحث الأذكار** (M): content pack + screen + local search + counters integration.
- **A3 — حزمة رمضان** (M): Imsak/Iftar reminders + Qada tracker (drift) + fasting-rules pack + app-side إمساكية + EG method preset.
- **A4 — خطة حفظ القرآن** (L): plan steps, repetition modes, reciter picker, plan audio player, progress persistence. No server.
- **A5 — Notification polish** (S/M): pre-adhan card, escalating Fajr alarm, أوقات النهي info, adhan recordings (post-R1) + polite rate prompt (D5).
- **A6 — Widgets** (M/L, D3 grant approved): prayer-times widget (+static ayah card). Android first, iOS if cheap.
- **A7 — مشاركة آية/دعاء كصورة** (S/M): RepaintBoundary card + `share_plus`.
- **A8 — قبلة: شمس/ظل + معايرة** (S/M).
- **A9 (post-D4, web-first):** in-app OSM mosques map — only after WW3 proves the value.

## 4) Web roadmap (after P3 finalization)

- **WW1 — SEO tools:** `/prayer-times/` + per-city pages (top Egyptian cities), `/imsakiah/`, `/qibla/`, `/tasbih/` — static Astro + tiny client JS; no new deps; existing budget gates apply.
- **WW2 — Evergreen content:** azkar/duas/asmaa pages generated at build time from app packs; sitemap + internal linking.
- **WW3 (D4 approved):** nearest-mosque page via Overpass, client-side fetch, no key.

## 5) Guardrails for every wave

Free & clean · no backend · offline-first · AR/EN parity (additive+symmetric ARB) · no new packages without a grant · **new media/content assets require a citable license verified BEFORE landing (D1/D2 rule)** · frozen tests untouched · bounded-pump widget tests · gates: `flutter analyze` 0 + full `flutter test` exact counts (web: check/unit/build/e2e/budget) · explicit-pathspec commits · **NO PUSH outside owner windows**.
