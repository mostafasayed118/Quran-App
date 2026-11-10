import '../db/app_database.dart';

/// A batched read of ayah rows.
///
/// Deliberately a **separate port** from `AyahLookup`: that interface is
/// implemented by frozen test doubles, so widening it would break every one of
/// them for a performance fix. A caller that holds this port resolves a whole
/// set in one query; a caller that does not keeps the per-id loop and behaves
/// exactly as before.
///
/// Row-typed for the same reason `AyahLookup` is: the caller maps rows to
/// entities at its own boundary (`verse_mapping.dart`).
abstract interface class AyahBatchLookup {
  /// The ayah rows whose ids are in [ids].
  ///
  /// Unknown ids are skipped. Order is unspecified — callers that need an order
  /// sort after mapping, which is what the folder list already does.
  Future<List<Ayah>> ayahsByIds(List<int> ids);
}
