import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../domain/khatma_progress.dart';
import '../domain/tracker_day.dart';
import 'tracker_cubit.dart';
import 'tracker_state.dart';

part 'tracker_cards.dart';
part 'tracker_wird.dart';

const TextStyle _streakLabelStyle = TextStyle(fontSize: 12);

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.worshipTracker)),
      body: AppContentFrame.form(
        child: BlocListener<TrackerCubit, TrackerState>(
          listenWhen: (previous, current) =>
              previous is TrackerReady &&
              !previous.actionFailed &&
              current is TrackerReady &&
              current.actionFailed,
          listener: (context, state) {
            AppToast.show(context, loc.genericError, tone: ToastTone.error);
            context.read<TrackerCubit>().acknowledgeActionFailure();
          },
          child: BlocBuilder<TrackerCubit, TrackerState>(
            builder: (context, state) => switch (state) {
              TrackerLoading() => const LoadingView(),
              TrackerFailed() =>
                errorPane(loc, onRetry: context.read<TrackerCubit>().reload),
              TrackerReady(
                :final today,
                :final streakDays,
                :final last7,
                :final khatmaAvailable,
                :final khatma,
              ) =>
                ListView(
                  padding: appScrollPadding(
                    context,
                    const EdgeInsets.all(AppSpacing.md),
                  ),
                  children: [
                    _TodayCard(today: today),
                    const SizedBox(height: AppSpacing.sm),
                    for (final slot in PrayerSlot.values)
                      _SlotTile(slot: slot, today: today),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      loc.last7Days,
                      style:
                          AppTheme.mutedAt(Theme.of(context).colorScheme, 12),
                    ),
                    const SizedBox(height: 6),
                    _Last7Row(last7: last7, today: today.day),
                    if (streakDays > 0) _StreakChip(streakDays: streakDays),
                    if (khatmaAvailable) ...[
                      const SizedBox(height: AppSpacing.md),
                      _WirdCard(progress: khatma),
                    ],
                  ],
                ),
            },
          ),
        ),
      ),
    );
  }
}
