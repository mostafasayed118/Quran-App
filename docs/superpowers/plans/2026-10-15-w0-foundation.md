# Quran Yahdi — Wave 0 (Foundation) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy app with a clean-architecture Flutter skeleton (proper identity, theme, AR/EN l10n, router, drift DB, DI) that builds, runs, and passes all gates.

**Architecture:** Feature-first clean architecture per spec §3. This wave ships foundation only — no feature content. Legacy `lib/` is deleted; git history, fonts, and icons are kept.

**Tech Stack:** Flutter latest stable, flutter_bloc + Freezed (installed now, used from W1), go_router, drift (sqlite), get_it, dio + connectivity_plus, flutter_localizations + intl, flutter_lints.

**Spec:** `docs/superpowers/specs/2026-10-15-quran-yahdi-rebuild-design.md` — executors read both.

## Global Constraints

- **Dependency freshness (owner rule, spec §7):** add packages only via `flutter pub add <pkg>` so each resolves to the latest stable at execution time; no deprecated/unmaintained packages; final `flutter pub outdated` audit in Task 10; `pubspec.lock` committed every commit that touches deps.
- `flutter analyze` must finish at **0 issues** (flutter_lints). All tests pass. Report exact counts.
- Commits: explicit pathspecs ONLY (never `git add -A` / `git add .`), one rollback unit per commit, messages `type(w0): summary`. **NO push** — local commits only until the owner approves a push window.
- **Identity:** pubspec name `quran_yahdi`, applicationId/namespace `com.mostafasayed.quranyahdi`, display name AR `قرآن يَهدي` / EN `Quran Yahdi`.
- Colors come exclusively from `core/theme/` tokens (spec D6 values) — no raw `Colors.*` outside theme files.
- Platforms: Android only. Delete `web/ linux/ windows/ macos/` in Task 1. `ios/` untouched. Working dir = repo root.

---

### Task 1: Baseline + prune non-mobile platforms

**Files:**
- Delete: `web/`, `linux/`, `windows/`, `macos/`

- [ ] **Step 1: Record baseline (verbatim in final report)**

```powershell
git rev-parse HEAD; git status --porcelain; flutter --version
```
Expected: HEAD = current `main` tip, clean tree.

- [ ] **Step 2: Remove platforms**

```powershell
git rm -r --quiet web linux windows macos
flutter pub get
```

- [ ] **Step 3: Commit**

```powershell
git commit -m "chore(w0): prune desktop/web platform dirs (mobile-only target)" -- web linux windows macos
```

---

### Task 2: pubspec identity + latest-stable deps + strict analysis + Android ID

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `android/app/build.gradle`, `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Produces: package set all later tasks consume — `flutter_bloc`, `freezed_annotation`, `go_router`, `drift`, `get_it`, `dio`, `connectivity_plus`, `shared_preferences`; dev: `build_runner`, `freezed`, `drift_dev`, `flutter_lints`; build-tools moved to dev: `flutter_launcher_icons`, `flutter_native_splash`.
- Produces: importable package name `package:quran_yahdi/...` (Task 3+ use it).

- [ ] **Step 1: Rename pubspec package** — in `pubspec.yaml` set `name: quran_yahdi` (replaces `quran_app`), keep `version: 1.0.0+1`. Update description to `Quran Yahdi - a complete offline-first Islamic companion app`.

- [ ] **Step 2: Add runtime deps (latest stable each)**

```powershell
flutter pub get
flutter pub add flutter_bloc freezed_annotation go_router drift get_it dio connectivity_plus shared_preferences
```

- [ ] **Step 3: Add dev deps + relocate build tools**

```powershell
flutter pub add --dev build_runner freezed drift_dev flutter_lints
flutter pub remove flutter_launcher_icons flutter_native_splash
flutter pub add --dev flutter_launcher_icons flutter_native_splash
```

- [ ] **Step 4: Remove dead deps**

```powershell
flutter pub remove arabic_numbers cupertino_icons device_preview share_plus url_launcher scrollable_positioned_list
```
(share_plus/url_launcher/scrollable_positioned_list return with their features in later waves — YAGNI now)

- [ ] **Step 5: Replace `analysis_options.yaml` entirely**

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true

linter:
  rules:
    prefer_const_constructors: true
    prefer_final_locals: true
    avoid_print: true
```

- [ ] **Step 6: Android identity** — in `android/app/build.gradle` set both:
```gradle
namespace = "com.mostafasayed.quranyahdi"
```
and inside `defaultConfig`:
```gradle
applicationId = "com.mostafasayed.quranyahdi"
```
In `android/app/src/main/AndroidManifest.xml` set `android:label="قرآن يَهدي"`.
(If either file cannot be located at these exact paths, STOP and report — no guessing.)

- [ ] **Step 7: Gates + commit**

```powershell
flutter pub outdated
flutter analyze
```
Expected: analyze 0 issues OR a bounded set inside legacy `lib/` only (Task 3 deletes it immediately after; list it in the report — anything outside `lib/` = STOP).
```powershell
git add pubspec.yaml pubspec.lock analysis_options.yaml android/app/build.gradle android/app/src/main/AndroidManifest.xml
git commit -m "chore(w0): package identity quran_yahdi, latest-stable 2026 deps, flutter_lints, android id"
```

---

### Task 3: Delete legacy `lib/`, bootstrap app + smoke test

**Files:**
- Delete: everything in `lib/`
- Create: `lib/main.dart`, `lib/app/app.dart`, `lib/core/theme/app_theme.dart` (provisional), `test/smoke_test.dart`

**Interfaces:**
- Produces: `QuranYahdiApp` (root widget; Tasks 5–6 extend it in place).

- [ ] **Step 1: Delete legacy code**

```powershell
git rm -r --quiet lib
```

- [ ] **Step 2: Write failing test** — `test/smoke_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/app/app.dart';

void main() {
  testWidgets('app boots without throwing', (tester) async {
    await tester.pumpWidget(const QuranYahdiApp());
    expect(find.byType(QuranYahdiApp), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run → expect FAIL (missing files)**

```powershell
flutter test test/smoke_test.dart
```

- [ ] **Step 4: Provisional `lib/core/theme/app_theme.dart`** (final theming lands in Task 4 — keep the snippet below exactly as shown)

```dart
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(useMaterial3: true);
  static ThemeData get dark => ThemeData(useMaterial3: true, brightness: Brightness.dark);
}
```

- [ ] **Step 5: `lib/app/app.dart`**

```dart
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class QuranYahdiApp extends StatelessWidget {
  const QuranYahdiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Yahdi',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(child: Text('قرآن يَهدي')),
      ),
    );
  }
}
```

- [ ] **Step 6: `lib/main.dart`**

```dart
import 'package:flutter/material.dart';

import 'app/app.dart';

void main() {
  runApp(const QuranYahdiApp());
}
```

- [ ] **Step 7: Gates + commit**

```powershell
flutter test test/smoke_test.dart
flutter analyze
git add test/smoke_test.dart lib/main.dart lib/app/app.dart lib/core/theme/app_theme.dart lib
git commit -m "feat(w0): delete legacy lib; bootstrap QuranYahdiApp"
```
(The trailing `lib` pathspec bundles Task 3 Step 1's staged deletions with the new files as one rollback unit.)

---

### Task 4: D6 design tokens + real light/dark themes

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Modify: `lib/core/theme/app_theme.dart` (replace provisional — final version below)
- Test: `test/theme_test.dart`

**Interfaces:**
- Produces: `AppColors` (static D6 tokens), `AppTheme.light`, `AppTheme.dark`, `QuranFonts.quran = 'HafsSmart'`, `QuranFonts.meQuran = 'me_quran'`, `QuranFonts.ui = 'Cairo'`.

- [ ] **Step 1: Failing test** — `test/theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_colors.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';

void main() {
  test('D6 palette tokens match spec', () {
    expect(AppColors.primaryBeige, const Color(0xFFF1EAD7));
    expect(AppColors.beigeSurface, const Color(0xFFE7DECB));
    expect(AppColors.emerald, const Color(0xFF3E6B58));
    expect(AppColors.emeraldDark, const Color(0xFF2E5244));
    expect(AppColors.emeraldLight, const Color(0xFFE4EEE9));
    expect(AppColors.gold, const Color(0xFFE3A53E));
    expect(AppColors.goldLight, const Color(0xFFF7EAD2));
    expect(AppColors.pageBackground, const Color(0xFFEFE9DA));
    expect(AppColors.ink, const Color(0xFF232D28));
  });

  test('light and dark themes differ in brightness', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });

  test('font family constants', () {
    expect(QuranFonts.quran, 'HafsSmart');
    expect(QuranFonts.meQuran, 'me_quran');
    expect(QuranFonts.ui, 'Cairo');
  });
}
```

- [ ] **Step 2: Run → expect FAIL (app_colors.dart missing)**

- [ ] **Step 3: Implement `lib/core/theme/app_colors.dart`**

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primaryBeige = Color(0xFFF1EAD7);
  static const beigeSurface = Color(0xFFE7DECB);
  static const emerald = Color(0xFF3E6B58);
  static const emeraldDark = Color(0xFF2E5244);
  static const emeraldLight = Color(0xFFE4EEE9);
  static const gold = Color(0xFFE3A53E);
  static const goldLight = Color(0xFFF7EAD2);
  static const pageBackground = Color(0xFFEFE9DA);
  static const ink = Color(0xFF232D28);
  static const muted = Color(0xFF6E7B74);
  static const hairline = Color(0xFFD9D2BF);
  static const cardBackground = Color(0xFFFFFDF7);
  static const danger = Color(0xFFB3452F);
}
```

- [ ] **Step 4: Replace `lib/core/theme/app_theme.dart` entirely**

```dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class QuranFonts {
  static const quran = 'HafsSmart';
  static const meQuran = 'me_quran';
  static const ui = 'Cairo';
}

abstract final class AppTheme {
  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: brightness,
      primary: isLight ? AppColors.emerald : AppColors.emeraldLight,
      onPrimary: isLight ? Colors.white : AppColors.ink,
      secondary: AppColors.gold,
      onSecondary: Colors.white,
      surface: isLight ? AppColors.cardBackground : const Color(0xFF16201B),
      onSurface: isLight ? AppColors.ink : const Color(0xFFE8E2D2),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.pageBackground : const Color(0xFF101410),
      fontFamily: QuranFonts.ui,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isLight ? AppColors.primaryBeige : const Color(0xFF16201B),
        foregroundColor:
            isLight ? AppColors.emeraldDark : const Color(0xFFE8E2D2),
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLight ? AppColors.hairline : const Color(0xFF2A362F),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Gates + commit**

```powershell
flutter test test/theme_test.dart
flutter analyze
git add lib/core/theme test/theme_test.dart
git commit -m "feat(w0): D6 design tokens + light/dark themes"
```

---

### Task 5: Localization scaffolding (AR default + EN)

**Files:**
- Create: `l10n.yaml`, `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb`
- Modify: `lib/app/app.dart` (attach localization delegates + supported locales; title from arb)
- Generated (committed): everything `flutter gen-l10n` emits under `lib/l10n/` (per `l10n.yaml` below).

**Interfaces:**
- Produces: generated `AppLocalizations` (class name derives from `output-localization-file`). Canonical usage adopted by all later waves: **`AppLocalizations.of(context)`**. New keys are added to both ARB files only, in their waves.

- [ ] **Step 1: Create `l10n.yaml`**

```yaml
arb-dir: lib/l10n
template-arb-file: app_ar.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

- [ ] **Step 2: Create `lib/l10n/app_ar.arb`**

```json
{
  "@@locale": "ar",
  "appName": "قرآن يَهدي",
  "home": "الرئيسية",
  "quran": "القرآن الكريم",
  "azkar": "الأذكار",
  "tasbih": "السبحة",
  "prayerTimes": "مواقيت الصلاة",
  "qibla": "القبلة",
  "duasAndRuqyah": "الأدعية والرقية",
  "worshipTracker": "تتبع العبادات",
  "zakat": "الزكاة",
  "hijriCalendar": "التقويم الهجري",
  "asmaUlHusna": "أسماء الله الحسنى",
  "settings": "الإعدادات",
  "recitations": "التلاوات",
  "library": "المكتبة",
  "nextPrayer": "الصلاة القادمة",
  "continueReading": "متابعة القراءة"
}
```

- [ ] **Step 3: Create `lib/l10n/app_en.arb`** (same key set)

```json
{
  "@@locale": "en",
  "appName": "Quran Yahdi",
  "home": "Home",
  "quran": "Quran",
  "azkar": "Azkar",
  "tasbih": "Tasbih",
  "prayerTimes": "Prayer Times",
  "qibla": "Qibla",
  "duasAndRuqyah": "Duas & Ruqyah",
  "worshipTracker": "Worship Tracker",
  "zakat": "Zakat",
  "hijriCalendar": "Hijri Calendar",
  "asmaUlHusna": "99 Names of Allah",
  "settings": "Settings",
  "recitations": "Recitations",
  "library": "Library",
  "nextPrayer": "Next Prayer",
  "continueReading": "Continue Reading"
}
```

- [ ] **Step 4: Generate**

```powershell
flutter gen-l10n
```
Expected: `lib/l10n/app_localizations.dart` + `app_localizations_ar.dart` + `app_localizations_en.dart`.

- [ ] **Step 5: Replace `lib/app/app.dart`** (routing still via `home:` — router arrives in Task 6)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class QuranYahdiApp extends StatelessWidget {
  const QuranYahdiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(
        body: Center(child: Text('قرآن يَهدي')),
      ),
    );
  }
}
```

- [ ] **Step 6: `flutter pub add flutter_localizations intl --sdk=flutter` if not already present (intl arrives via flutter_localizations), then gates + commit**

```powershell
flutter pub add flutter_localizations --sdk=flutter
flutter pub get
flutter gen-l10n
flutter test test/smoke_test.dart
flutter analyze
git add l10n.yaml lib/l10n lib/app/app.dart pubspec.yaml pubspec.lock
git commit -m "feat(w0): AR/EN localization scaffolding (ARB + delegates)"
```
(If `intl` is missing as a direct dep when needed in later waves, add it then — YAGNI now.)

---

### Task 6: go_router 14-route map + placeholder screens

**Files:**
- Create: `lib/core/widgets/placeholder_screen.dart`, `lib/app/router.dart`
- Modify: `lib/app/app.dart` (switch to `MaterialApp.router`)
- Test: `test/router_test.dart`

**Interfaces:**
- Consumes: `AppTheme` (via app.dart), nothing else.
- Produces: `AppRouter.router` (GoRouter). Named route paths (exact strings later waves deep-link against): `/home`, `/quran`, `/recitation`, `/library`, `/prayer-times`, `/qibla`, `/azkar`, `/tasbih`, `/duas`, `/worship`, `/zakat`, `/hijri`, `/asma`, `/settings`. Each placeholder screen later gets replaced in its own feature wave with `const XScreen({super.key})` signatures.

- [ ] **Step 1: Failing test** — `test/router_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/app/router.dart';

void main() {
  test('router exposes the approved 14-route map', () {
    final paths = AppRouter.router.configuration.routes.keys.toSet();
    expect(paths, containsAll(<String>[
      '/home', '/quran', '/recitation', '/library', '/prayer-times',
      '/qibla', '/azkar', '/tasbih', '/duas', '/worship',
      '/zakat', '/hijri', '/asma', '/settings',
    ]));
  });
}
```

- [ ] **Step 2: Run → expect FAIL**

- [ ] **Step 3: Implement `lib/core/widgets/placeholder_screen.dart`**

```dart
import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement `lib/app/router.dart`**

```dart
import 'package:go_router/go_router.dart';

import '../core/widgets/placeholder_screen.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const PlaceholderScreen(title: 'الرئيسية')),
      GoRoute(path: '/quran', builder: (_, _) => const PlaceholderScreen(title: 'القرآن الكريم')),
      GoRoute(path: '/recitation', builder: (_, _) => const PlaceholderScreen(title: 'التلاوات')),
      GoRoute(path: '/library', builder: (_, _) => const PlaceholderScreen(title: 'المكتبة')),
      GoRoute(path: '/prayer-times', builder: (_, _) => const PlaceholderScreen(title: 'مواقيت الصلاة')),
      GoRoute(path: '/qibla', builder: (_, _) => const PlaceholderScreen(title: 'القبلة')),
      GoRoute(path: '/azkar', builder: (_, _) => const PlaceholderScreen(title: 'الأذكار')),
      GoRoute(path: '/tasbih', builder: (_, _) => const PlaceholderScreen(title: 'السبحة')),
      GoRoute(path: '/duas', builder: (_, _) => const PlaceholderScreen(title: 'الأدعية والرقية')),
      GoRoute(path: '/worship', builder: (_, _) => const PlaceholderScreen(title: 'تتبع العبادات')),
      GoRoute(path: '/zakat', builder: (_, _) => const PlaceholderScreen(title: 'الزكاة')),
      GoRoute(path: '/hijri', builder: (_, _) => const PlaceholderScreen(title: 'التقويم الهجري')),
      GoRoute(path: '/asma', builder: (_, _) => const PlaceholderScreen(title: 'أسماء الله الحسنى')),
      GoRoute(path: '/settings', builder: (_, _) => const PlaceholderScreen(title: 'الإعدادات')),
    ],
  );
}
```
(Placeholder titles are temporary strings; feature waves replace them with `AppLocalizations` getters — no l10n import needed in this file.)

- [ ] **Step 5: Wire `app.dart`** — in Task 5's `MaterialApp`, delete the `home:` line and add:
```dart
      routerConfig: AppRouter.router,
```
plus `import 'router.dart';`

- [ ] **Step 6: Gates + commit**

```powershell
flutter test test/router_test.dart
flutter test
flutter analyze
git add lib/app lib/core/widgets/placeholder_screen.dart test/router_test.dart
git commit -m "feat(w0): go_router 14-route map + placeholder screens"
```

---

### Task 7: Drift schema v1 + real connection + migration test

**Files:**
- Create: `lib/core/db/tables.dart`, `lib/core/db/app_database.dart`, `lib/core/db/connection.dart`, generated `lib/core/db/app_database.g.dart`
- Modify: `pubspec.yaml`/`pubspec.lock` (`flutter pub add path_provider path`)
- Test: `test/db_migration_test.dart`

**Interfaces:**
- Produces: `AppDatabase` (drift `_$AppDatabase` base via `@DriftDatabase`), `AppDatabase.test(QueryExecutor)` for tests, `AppDatabase()` opening `quran_yahdi.sqlite` via `NativeDatabase.createInBackground` under `getApplicationSupportDirectory()`. Tables (exact names from spec §5): `Surahs`, `Ayahs`, `Bookmarks`, `KhatmaProgress`, `PrayerLog`, `InstalledPacks`, `Downloads`, `SettingsTable`. `schemaVersion = 1`.

- [ ] **Step 1: Add deps**

```powershell
flutter pub add path_provider path
```

- [ ] **Step 2: Failing test** — `test/db_migration_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('v1 schema creates all 8 tables and surah rows roundtrip', () async {
    expect(db.allTables.length, 8);

    await db.into(db.surahs).insert(
      SurahsCompanion.insert(
        id: 1,
        nameAr: 'الفاتحة',
        nameEn: 'Al-Fatihah',
        revelationType: 'المكية',
        ayahCount: 7,
        pagesStart: 1,
        pagesEnd: 1,
      ),
    );

    final fetched = await db.select(db.surahs).get();
    expect(fetched.single.nameAr, 'الفاتحة');
    expect(fetched.single.pagesEnd, 1);
  });

  test('ayahs table roundtrips uthmani + imlaei text', () async {
    await db.into(db.ayahs).insert(
      AyahsCompanion.insert(
        id: 1,
        surahId: 1,
        numberInSurah: 1,
        juz: 1,
        page: 1,
        textUthmani: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        textImlaei: 'بسم الله الرحمن الرحيم',
      ),
    );

    final fetched = await db.select(db.ayahs).get();
    expect(fetched.single.textImlaei, 'بسم الله الرحمن الرحيم');
    expect(fetched.single.sajda, false);
  });
}
```

- [ ] **Step 3: Run → expect FAIL (missing files)**

- [ ] **Step 4: Implement `lib/core/db/tables.dart`**

```dart
import 'package:drift/drift.dart';

class Surahs extends Table {
  IntColumn get id => integer()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  TextColumn get revelationType => text()();
  IntColumn get ayahCount => integer()();
  IntColumn get pagesStart => integer()();
  IntColumn get pagesEnd => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

class Ayahs extends Table {
  IntColumn get id => integer()(); // 1..6236 global ayah number
  IntColumn get surahId => integer()();
  IntColumn get numberInSurah => integer()();
  IntColumn get juz => integer()();
  IntColumn get page => integer()();
  IntColumn get lineStart => integer().nullable()();
  IntColumn get lineEnd => integer().nullable()();
  TextColumn get textUthmani => text()();
  TextColumn get textImlaei => text()();
  BoolColumn get sajda => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ayahId => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class KhatmaProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ayahId => integer()();
  IntColumn get targetPages => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class PrayerLog extends Table {
  DateColumn get day => date()();
  BoolColumn get fajr => boolean().withDefault(const Constant(false))();
  BoolColumn get dhuhr => boolean().withDefault(const Constant(false))();
  BoolColumn get asr => boolean().withDefault(const Constant(false))();
  BoolColumn get maghrib => boolean().withDefault(const Constant(false))();
  BoolColumn get isha => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {day};
}

class InstalledPacks extends Table {
  TextColumn get packId => text()();
  TextColumn get kind => text()(); // tafsir | translation | hadith
  TextColumn get language => text()();
  TextColumn get title => text()();
  RealColumn get sizeMb => real()();
  TextColumn get version => text()();
  DateTimeColumn get installedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {packId};
}

class Downloads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get reciterId => text()();
  IntColumn get surahId => integer()();
  TextColumn get status => text()(); // queued|downloading|done|failed
  IntColumn get bytes => integer().withDefault(const Constant(0))();
  TextColumn get path => text()();
}

class SettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}
```

- [ ] **Step 5: Implement `lib/core/db/connection.dart`**

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<QueryExecutor> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'quran_yahdi.sqlite'));
  return NativeDatabase.createInBackground(file);
}
```

- [ ] **Step 6: Implement `lib/core/db/app_database.dart`**

```dart
import 'package:drift/drift.dart';

import 'connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Surahs,
  Ayahs,
  Bookmarks,
  KhatmaProgress,
  PrayerLog,
  InstalledPacks,
  Downloads,
  SettingsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @visibleForTesting
  AppDatabase.test(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _open() => LazyDatabase(() => openAppDatabase());
}
```
(If `@visibleForTesting` needs an import, add `package:meta/meta.dart` or `package:flutter/foundation.dart` — use `package:meta/meta.dart` via `drift`'s transitive availability; if the analyzer complains, `flutter pub add meta` and import it.)

- [ ] **Step 7: Generate code**

```powershell
dart run build_runner build --delete-conflicting-outputs
```
Expected: `app_database.g.dart` created next to `app_database.dart`.

- [ ] **Step 8: Gates + commit**

```powershell
flutter test test/db_migration_test.dart
flutter analyze
git add lib/core/db test/db_migration_test.dart pubspec.yaml pubspec.lock
git commit -m "feat(w0): drift schema v1 (8 tables) + real-file connection + migration tests"
```

---

### Task 8: DI registration (get_it) + wiring into main

**Files:**
- Create: `lib/core/di/injector.dart`
- Modify: `lib/main.dart`
- Test: `test/injector_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` (Task 7).
- Produces: `getIt` (GetIt instance) and `Future<void> configureDependencies()`, idempotent; later waves register repositories here.

- [ ] **Step 1: Failing test** — `test/injector_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/di/injector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // path_provider has no platform channel under pure flutter_test —
    // route it to a temp dir so the real-file database can open.
    final tmp = Directory.systemTemp.createTempSync('quran_yahdi_db_test');
    PathProviderPlatform.overrideForTests(getApplicationSupportPath: tmp.path);
  });

  test('configureDependencies registers a working AppDatabase', () async {
    await configureDependencies();
    final db = getIt<AppDatabase>();
    final row = await db.customSelect('SELECT 1 AS one').getSingle();
    expect(row.read<int>('one'), 1);
  });
}
```
(`path_provider_platform_interface` arrives transitively with `path_provider` — import it directly without adding it to pubspec.)

- [ ] **Step 2: Run → expect FAIL (injector missing)**

- [ ] **Step 3: Implement `lib/core/di/injector.dart`**

```dart
import 'package:get_it/get_it.dart';

import '../db/app_database.dart';

final getIt = GetIt.instance;

bool _configured = false;

Future<void> configureDependencies() async {
  if (_configured) return;
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
  _configured = true;
}
```

- [ ] **Step 4: Replace `lib/main.dart`**

```dart
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const QuranYahdiApp());
}
```

- [ ] **Step 5: Gates + commit**

```powershell
flutter test test/injector_test.dart
flutter test
flutter analyze
git add lib/core/di lib/main.dart test/injector_test.dart
git commit -m "feat(w0): get_it DI + AppDatabase registration"
```

---

### Task 9: GitHub Actions CI

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Write `.github/workflows/ci.yml`**

```yaml
name: ci
on:
  push:
    branches: [main]
  pull_request:

jobs:
  analyze-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter gen-l10n
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test
```

- [ ] **Step 2: Commit (CI proof lands on the first approved push — note that in the report)**

```powershell
git add .github/workflows/ci.yml
git commit -m "ci: analyze + test on push and PR"
```

---

### Task 10: Final gates + freshness audit + handoff report

- [ ] **Step 1: Full suite + clean build output**

```powershell
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
```
Expected: analyze 0 issues, all tests pass — record exact test count.

- [ ] **Step 2: Freshness audit**

```powershell
flutter pub outdated
```
Expected: all direct deps current; any "discontinued" = STOP and report.

- [ ] **Step 3: Worktree must be clean**

```powershell
git status --porcelain
```
Expected: empty.

- [ ] **Step 4: Handoff report (terminal message)** — baseline HEAD, per-commit list (sha + message), final test count, analyze verdict, `pub outdated` verdict, worktree status. No push. PM takes over from here.

---

## Self-Review (run once by the PM; the verifier re-checks)

- **Spec coverage (W0 slice):** platform prune (§3 platforms) = Task 1; identity (§2/D4 + App ID) = Tasks 2; deps + lints (§7) = Task 2; scaffold + smoke (§3) = Task 3; theme tokens (§6/D6) = Task 4; l10n AR/EN (§2/D2) = Task 5; route map (§6/§9 W0) = Task 6; drift core (§5) = Task 7; DI (§3) = Task 8; CI (§7) = Task 9; audit/close (§7 freshness) = Task 10. Feature content = W1+ (explicit non-goal for this plan).
- **Placeholders:** none expected — every code step carries complete code; no "TBD/TODO".
- **Type consistency:** `QuranYahdiApp` (T3) reused in T5/T6; `AppTheme`/`AppColors`/`QuranFonts` (T4) used by T5/T6; `AppRouter.router` (T6) consumed by app.dart; `AppDatabase`/companion types (T7) consumed by T8 test; `configureDependencies`/`getIt` (T8) wired in `main.dart`.
