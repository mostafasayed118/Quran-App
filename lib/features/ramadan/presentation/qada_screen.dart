import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import 'qada_cubit.dart';
import 'qada_state.dart';

/// The missed-fast list: count, dates, add and delete.
class QadaScreen extends StatelessWidget {
  /// Creates the screen.
  const QadaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<QadaCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.qadaTitle),
        actions: [
          BlocBuilder<QadaCubit, QadaState>(
            builder: (context, state) => switch (state) {
              QadaReady() => IconButton(
                  tooltip: loc.qadaAdd,
                  icon: const Icon(Icons.add),
                  onPressed: () => _pickDate(context, cubit),
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
      body: AppContentFrame.form(
        child: BlocBuilder<QadaCubit, QadaState>(
          builder: (context, state) => switch (state) {
            QadaLoading() => const LoadingView(),
            QadaFailed() => errorPane(loc, onRetry: cubit.start),
            QadaReady(:final dates) when dates.isEmpty =>
              EmptyState(loc.qadaEmpty, icon: Icons.event_available_outlined),
            QadaReady(:final dates) => _QadaList(dates: dates),
          },
        ),
      ),
    );
  }
}

Future<void> _pickDate(BuildContext context, QadaCubit cubit) async {
  final loc = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final now = DateTime.now();
  final yesterday =
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
  final picked = await showDatePicker(
    context: context,
    initialDate: yesterday,
    // Missed fasts accumulate over years, not months; ten years covers a
    // normal backlog without turning the picker into a scroll marathon.
    firstDate: DateTime(now.year - 10),
    lastDate: yesterday,
    helpText: loc.qadaPickDate,
  );
  if (picked == null) return;
  final saved = await cubit.add(picked);
  if (!saved) {
    AppToast.showOn(messenger, loc.genericError, tone: ToastTone.error);
  }
}

class _QadaList extends StatelessWidget {
  const _QadaList({required this.dates});

  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final months = MaterialLocalizations.of(context);
    return ListView(
      padding: EdgeInsets.only(bottom: appBottomInset(context)),
      children: [
        Card(
          margin: const EdgeInsets.all(AppSpacing.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              loc.qadaCount(loc.number(dates.length)),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        for (final date in dates)
          ListTile(
            title: Text(months.formatMediumDate(date)),
            trailing: IconButton(
              tooltip: loc.libraryDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, date),
            ),
          ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, DateTime date) async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<QadaCubit>();
    final months = MaterialLocalizations.of(context);
    final confirmed = await confirmDeleteDialog(
      context,
      title: loc.qadaDeleteTitle,
      body: loc.qadaDeleteBody(months.formatMediumDate(date)),
    );
    if (!confirmed) return;
    final saved = await cubit.remove(date);
    if (!saved) {
      AppToast.showOn(messenger, loc.genericError, tone: ToastTone.error);
    }
  }
}
