# Quran-App Recovery Plan

## Executive Summary

Quran-App is a functional Flutter app displaying the full Quran (114 surahs, ~6236 verses) in Arabic with two custom fonts. Loads 7.4MB JSON at startup, supports verse-by-verse and Mushaf reading modes, bookmarks, and font-size settings via SharedPreferences. Prior recovery modernized dependencies and fixed analyzer issues. Currently compiles and builds. Zero tests. Global mutable state, dynamic types, no routing, no DI.

## Tracking Table

| ID | Area | Severity | Planned action | Status | Verification |
|---|---|---|---|---|---|
| QN-01 | Zero tests | Blocker | Add test suite | Not started | Tests pass |
| QN-02 | Global mutable state | Critical | Migrate to Riverpod/Provider | Not started | No globals |
| QN-03 | Dynamic types everywhere | High | Create typed models | Not started | No dynamic types |
| QN-04 | JSON loaded eagerly (7.4MB) | High | Lazy-load or isolate | Not started | No jank |
| QN-05 | device_preview in production | High | Move to dev_dependencies | Not started | No preview in release |
| QN-06 | No error handling on load | High | Add error state + retry | Not started | Error UI shown |
| QN-07 | Unused dependency: arabic_numbers | Medium | Remove | Not started | No unused deps |
| QN-08 | Build tools in dependencies | Medium | Move to dev_dependencies | Not started | Clean deps |
| QN-09 | com.example bundle IDs | Medium | Change to real IDs | Not started | Unique IDs |
| QN-10 | Dark mode defined but unwired | Medium | Add toggle | Not started | Dark mode works |
| QN-11 | No routing (Navigator.push only) | Medium | Add go_router | Not started | Declarative routing |
| QN-12 | Filename typo: surah_bulider | Medium | Rename to surah_builder | Not started | Correct spelling |
| QN-13 | commons.dart is junk drawer | Low | Split into focused files | Not started | Clean organization |
| QN-14 | No i18n (hardcoded strings) | Low | Add ARB files | Not started | EN/AR support |
| QN-15 | No accessibility labels | Low | Add Semantics | Not started | Screen reader works |
| QN-16 | No release signing | Low | Configure keystore | Not started | Release builds signed |

## Phased Recovery Plan

### Phase 1: Safety Net (Week 1)
- Create test directory with smoke tests
- Add unit tests for ArabicNumbers, QuranState
- Move device_preview, flutter_launcher_icons, flutter_native_splash to dev_dependencies
- Remove unused arabic_numbers
- **Acceptance:** flutter analyze + flutter test pass

### Phase 2: Type Safety (Week 2)
- Create Surah and Verse model classes
- Refactor QuranState to parse into typed models
- Type SurahBuilder and VerseBuilder
- **Acceptance:** No dynamic types, models validated

### Phase 3: State Management (Week 3)
- Add flutter_riverpod
- Convert QuranState to AsyncNotifier
- Remove all global mutable state
- Scope scroll controllers
- **Acceptance:** No globals, state is testable

### Phase 4: Navigation & UX (Week 4)
- Add go_router for declarative routing
- Wire dark mode toggle
- Add error state with retry
- Add accessibility labels
- **Acceptance:** Routing works, dark mode toggleable

### Phase 5: Production Hardening (Week 5)
- Change bundle IDs
- Add release signing
- Add i18n with ARB files
- Performance audit
- **Acceptance:** Production-ready quality
