// Compatibility shim: the composition root lives in the app layer
// (`lib/app/di/injector.dart`) because core must not know the features.
//
// The frozen test files still import this path, so it re-exports the new
// location. Code under `lib/app/` should import
// `package:quran_yahdi/app/di/injector.dart` directly; code under
// `lib/features/` must NOT import the app layer at all (the architecture
// guard pins that) — resolve through get_it (`GetIt.instance`) instead.
export 'package:quran_yahdi/app/di/injector.dart';
