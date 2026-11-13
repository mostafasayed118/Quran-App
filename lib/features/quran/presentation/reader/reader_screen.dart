import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/domain/quran_limits.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_type.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../library/presentation/ayah_sheet/library_sheet.dart';
import '../../../recitation/presentation/playback/mini_player_bar.dart';
import '../../../recitation/presentation/playback/playback_cubit.dart';
import '../../data/reader_layout_source.dart';
import '../../domain/verse.dart';
import 'reader_cubit.dart';
import 'reader_state.dart';
import 'verse_share_sheet.dart';

part 'reader_error_views.dart';
part 'reader_actions.dart';
part 'reader_verses.dart';
part 'reader_mushaf.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      buildWhen: readerShellShouldRebuild,
      builder: (context, state) => switch (state) {
        ReaderLoading() =>
          const Scaffold(body: AppContentFrame.reading(child: LoadingView())),
        ReaderFailed() => _ReaderErrorView(state: state),
        ReaderReady() => _ReadyView(state: state),
      },
    );
  }
}

/// The reader shell rebuilds on every state change EXCEPT a bookmark-only
/// one: the bookmark UI carries its own subscription (one [BlocSelector] per
/// verse), so toggling a bookmark no longer rebuilds the whole Scaffold.
bool readerShellShouldRebuild(ReaderState previous, ReaderState current) {
  if (previous is! ReaderReady || current is! ReaderReady) return true;
  // Equal apart from the bookmarks means the shell has nothing new to show.
  return previous.copyWith(bookmarkedAyahIds: current.bookmarkedAyahIds) !=
      current;
}
