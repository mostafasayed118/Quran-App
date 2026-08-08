# The Quran App

A complete offline Quran reader for Flutter — all 114 surahs (~6,236 verses) bundled locally, with no network or API dependencies. Read verse-by-verse or in a full-page Mushaf layout, bookmark your place, and fine-tune the typography to your preference.

## Features

- **Full Quran content, offline** — all 114 surahs and verses bundled as a local JSON asset (~7.4 MB); works without internet.
- **Two reading modes** — switch between verse-by-verse scrolling and a traditional full-page Mushaf view.
- **Surah index** — scrollable list of the 114 surahs with a bookmarks shortcut.
- **Bookmarks** — save any ayah and jump straight back to it from the app drawer.
- **Typography settings** — independent font-size sliders for both Arabic and Mushaf modes, persisted across restarts.
- **Bundled Quran fonts** — `HafsSmart` and `me_quran` render the Arabic script correctly.
- **Share & links** — share your reading position, plus quick links to external references from the drawer.

## Getting started

Requirements: Flutter 3.x / Dart 3.5+ (Android, iOS, Web, desktop).

```bash
flutter pub get
flutter run
```

No configuration, API keys, or accounts are required — the text travels with the app.

## Project structure

```
lib/
├── core/
│   ├── common/          # shared singletons, static surah data, QuranState
│   ├── widgets/         # drawer widget
│   └── strings.dart
└── features/
    └── quran/
        ├── data/        # JSON assets
        └── presentation/
            ├── screens/ # surah index, reader, settings
            └── components/ # verse/surah builders, basmala
```

State is managed through a global `QuranState` singleton (settings + bookmark persistence over `shared_preferences`).

## Test

```bash
flutter analyze   # 0 issues
flutter test
```

## Roadmap (see `RECOVERY_PLAN.md`)

- Typed data models + lazy JSON loading for faster startup
- Migrate the global singleton to Riverpod
- Dark mode + system theme support
- Localization (AR/EN) and a proper router

## Contributing

Contributions are welcome — open an issue or submit a PR.

## License

All rights reserved. Portfolio/demo project.