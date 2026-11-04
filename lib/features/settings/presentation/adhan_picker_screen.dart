import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/adhan_catalog.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_pane.dart';
import '../../../core/widgets/loading_and_error_views.dart';
import '../../../l10n/app_localizations.dart';
import 'adhan_picker_cubit.dart';
import 'adhan_picker_state.dart';

/// Lets the user choose the adhan heard for the prayer reminder.
///
/// Two sections: the global choice and the Fajr override. The override's first
/// row is an explicit "same as default", so clearing it is a visible choice
/// rather than an absence the user has to infer.
class AdhanPickerScreen extends StatefulWidget {
  /// Creates the screen; the cubit comes from `RouteCubitScope`.
  const AdhanPickerScreen({super.key});

  @override
  State<AdhanPickerScreen> createState() => _AdhanPickerScreenState();
}

class _AdhanPickerScreenState extends State<AdhanPickerScreen> {
  late final AdhanPickerCubit _cubit;

  @override
  void initState() {
    super.initState();
    // `read` in initState is safe (it never subscribes); BlocBuilder below owns
    // the rebuilds.
    _cubit = context.read<AdhanPickerCubit>();
  }

  @override
  void dispose() {
    // A preview must not outlive the screen that started it.
    _cubit.stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.adhanTitle)),
      body: BlocBuilder<AdhanPickerCubit, AdhanPickerState>(
        builder: (context, state) => switch (state) {
          AdhanPickerLoading() => const LoadingView(),
          AdhanPickerFailed() => errorPane(loc, onRetry: _cubit.start),
          AdhanPickerReady() => _body(loc, state),
        },
      ),
    );
  }

  Widget _body(AppLocalizations loc, AdhanPickerReady state) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        _SectionHeader(text: loc.adhanDefaultSection),
        for (final track in kAdhanCatalog)
          _AdhanRow(
            track: track,
            selected: state.adhanId == track.id,
            previewing: state.previewingId == track.id,
            onSelect: () => _cubit.select(track.id),
            onTogglePreview: () => _togglePreview(track.id),
          ),
        const Divider(height: AppSpacing.xl),
        _SectionHeader(text: loc.adhanFajrSection),
        _AdhanRow(
          title: loc.adhanSameAsDefault,
          selected: state.fajrAdhanId == null,
          previewing: false,
          // The default row has nothing of its own to audition.
          onSelect: () => _cubit.selectFajr(null),
        ),
        for (final track in kAdhanCatalog)
          _AdhanRow(
            track: track,
            selected: state.fajrAdhanId == track.id,
            previewing: state.previewingId == track.id,
            onSelect: () => _cubit.selectFajr(track.id),
            onTogglePreview: () => _togglePreview(track.id),
          ),
      ],
    );
  }

  void _togglePreview(String id) {
    final state = _cubit.state;
    if (state is AdhanPickerReady && state.previewingId == id) {
      _cubit.stopPreview();
    } else {
      _cubit.preview(id);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: colors.primary),
      ),
    );
  }
}

/// One selectable adhan.
///
/// The trailing tick is the selection indicator instead of a `Radio`: the
/// row's primary action is selection, and a tappable tick reads as a radio
/// while staying trivially assertable in widget tests.
class _AdhanRow extends StatelessWidget {
  const _AdhanRow({
    this.track,
    this.title,
    required this.selected,
    required this.previewing,
    required this.onSelect,
    this.onTogglePreview,
  });

  final AdhanTrack? track;
  final String? title;
  final bool selected;
  final bool previewing;
  final VoidCallback onSelect;
  final VoidCallback? onTogglePreview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final label = title ?? track!.nameAr;
    final subtitle = track?.nameEn;

    return ListTile(
      leading: onTogglePreview == null
          ? null
          : IconButton(
              icon: Icon(
                previewing
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
              ),
              tooltip: previewing ? loc.adhanStopPreview : loc.adhanPreview,
              onPressed: onTogglePreview,
            ),
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? colors.primary : colors.outlineVariant,
      ),
      onTap: onSelect,
    );
  }
}
