// Compat: existing importers of this file keep resolving the search seam and
// its DTOs, which now live in domain/ so presentation stays off the data
// layer.
export '../domain/quran_search_source.dart';
