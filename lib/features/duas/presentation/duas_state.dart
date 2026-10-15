import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/dua_repository.dart';

part 'duas_state.freezed.dart';

enum DuasTab { duas, ruqyah }

class RuqyahResolved {
  const RuqyahResolved({
    required this.id,
    required this.isQuran,
    required this.displayText,
    this.citation,
    this.count = 1,
    this.reference,
  });

  final String id;
  final bool isQuran;
  final String displayText;
  final String? citation;
  final int count;
  final String? reference;
}

@freezed
sealed class DuasState with _$DuasState {
  const factory DuasState.loading({
    @Default(DuasTab.duas) DuasTab tab,
  }) = DuasLoading;

  const factory DuasState.duas({
    required List<String> categories,
    required List<DuaEntry> entries,
    @Default(null) String? selectedCategory,
  }) = DuasInView;

  const factory DuasState.ruqyah({
    required List<RuqyahResolved> entries,
  }) = RuqyahInView;
}
