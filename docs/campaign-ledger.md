# Quran Yahdi — PM Campaign Ledger (append-only, owner-facing)
Format: newest entries appended at the bottom. Every entry = independently verified at source by PM.

## W0 — Foundation — CLOSED 2026-10-15
- Scope: platform prune, identity (quran_yahdi / com.mostafasayed.quranyahdi / AR label), latest-stable 2026 deps (flutter_bloc 9.1.1, freezed 4.0.2, go_router 18.1.0, drift 2.35.2, get_it 9.3.0, dio 5.11.1, connectivity_plus 7.3.2), flutter_lints strict, legacy lib deleted (16 files came out), bootstrap + light/dark D6 themes, AR/EN l10n, go_router 14-route map, drift schema v1 (8 tables), get_it DI, first GitHub Actions CI.
- Verifier reproductions: flutter test 8/8, analyze 0 issues, APK debug artifact 175,678,239 bytes on disk (built after Kotlin 2.2.20 bump), pub outdated all-current/no-discontinued, final porcelain empty.
- Accepted deviations: D1 generate:true; D2 PrayerLog.day dateTime (no drift DateColumn); D3 meta dep; D4 Value(...) companions; D5 super-params; D6 go_router 18 test API + (_, __) under sdk ^3.5; D7 path_provider_platform_interface dev dep; D8 manual PathProviderPlatform override; D9 pathspec extension; D10 build_runner 2.16 dropped --delete-conflicting-outputs flag; D11 plan-checkbox commit; D12 flutter-tool analyzer.auto-exlude recurrence; D13 3 pre-existing PM docs commits honestly attributed; D14 STOP adjudicated → granted.
- Toolchain continuation (PROMPT 1b): Kotlin 2.1.0 → 2.2.20 (02b734c), dead `lints` dev-dep dropped + flutter-managed analyzer excludes accepted permanently (96d008b).
- State at close: 15 unpushed on main (3 PM docs + 12 executor). NO push performed — push window belongs to the owner.
- Forward notes: Gradle 9.1+/AGP 9+/Kotlin 2.3.20 future minima flagged by tool (non-blocking) — revisit in W7 polish. `assets/json/hafs_smart_v8.json` remains repo-tracked as the W1a import source (bundling removed from pubspec in W1a).

