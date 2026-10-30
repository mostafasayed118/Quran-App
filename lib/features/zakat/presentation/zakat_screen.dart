import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/zakat_calculator.dart';
import 'zakat_cubit.dart';
import 'zakat_state.dart';

const int _amountDecimals = 2;

const TextStyle _amountStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
);

const TextStyle _lineLabelStyle = TextStyle(fontSize: 13);

const TextStyle _lineValueStyle = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 14,
);

class ZakatScreen extends StatelessWidget {
  const ZakatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.zakat)),
      body: BlocBuilder<ZakatCubit, ZakatState>(
        builder: (context, state) {
          final ZakatReady ready = switch (state) {
            ZakatReady() => state,
          };
          final hasInvalid = <String>[
            ready.goldGrams,
            ready.silverGrams,
            ready.goldPrice,
            ready.silverPrice,
            ready.cash,
            ready.debts,
          ].any(_isInvalid);
          final needsNisabPrice =
              ready.result.nisabValue <= 0 && ready.result.zakatable > 0;
          final verdictText = hasInvalid
              ? loc.zakatFixInputs
              : needsNisabPrice
                  ? loc.zakatEnterPrice
                  : ready.result.due
                      ? loc.zakatDue
                      : loc.zakatNotDue;
          String? errorFor(String text) =>
              _isInvalid(text) ? loc.zakatInvalidNumber : null;
          return ListView(
            padding:
                appScrollPadding(context, const EdgeInsets.all(AppSpacing.md)),
            children: [
              _NisabToggle(ready: ready),
              const SizedBox(height: 10),
              _Field(
                  label: loc.goldGrams,
                  errorText: errorFor(ready.goldGrams),
                  onChanged: context.read<ZakatCubit>().setGoldGrams),
              _Field(
                  label: loc.silverGrams,
                  errorText: errorFor(ready.silverGrams),
                  onChanged: context.read<ZakatCubit>().setSilverGrams),
              _Field(
                  label: loc.goldPrice,
                  errorText: errorFor(ready.goldPrice),
                  onChanged: context.read<ZakatCubit>().setGoldPrice),
              _Field(
                  label: loc.silverPrice,
                  errorText: errorFor(ready.silverPrice),
                  onChanged: context.read<ZakatCubit>().setSilverPrice),
              _Field(
                  label: loc.cash,
                  errorText: errorFor(ready.cash),
                  onChanged: context.read<ZakatCubit>().setCash),
              _Field(
                  label: loc.debts,
                  errorText: errorFor(ready.debts),
                  onChanged: context.read<ZakatCubit>().setDebts),
              const SizedBox(height: 14),
              _SummaryCard(
                ready: ready,
                needsNisabPrice: needsNisabPrice,
                verdictText: verdictText,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NisabToggle extends StatelessWidget {
  const _NisabToggle({required this.ready});

  final ZakatReady ready;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment(
          value: false,
          label: Text(loc.nisabByGold),
          icon: const Icon(Icons.workspace_premium),
        ),
        ButtonSegment(
          value: true,
          label: Text(loc.nisabBySilver),
          icon: const Icon(Icons.monetization_on_outlined),
        ),
      ],
      selected: {ready.nisabBySilver},
      onSelectionChanged: (selection) =>
          context.read<ZakatCubit>().setNisabBySilver(
                selection.first,
              ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.ready,
    required this.needsNisabPrice,
    required this.verdictText,
  });

  final ZakatReady ready;
  final bool needsNisabPrice;
  final String verdictText;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ZakatLine(
                label: loc.zakatableLabel, value: ready.result.zakatable),
            _ZakatLine(label: loc.nisabLabel, value: ready.result.nisabValue),
            const SizedBox(height: AppSpacing.sm),
            Text(
              verdictText,
              textAlign: TextAlign.right,
              style: AppTheme.rowTitle.copyWith(
                color: ready.result.due
                    ? AppTheme.goldText(context)
                    : colors.onSurfaceVariant,
              ),
            ),
            if (!needsNisabPrice && ready.result.due)
              Text(
                ready.result.amount
                    .toStringAsFixed(_amountDecimals)
                    .toArabicIndicDigits,
                textAlign: TextAlign.right,
                style: _amountStyle.copyWith(color: colors.primary),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              loc.zakatRateNote,
              style: AppTheme.mutedFootnote(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZakatLine extends StatelessWidget {
  const _ZakatLine({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              label,
              style: _lineLabelStyle,
            ),
          ),
          Text(
            value.toStringAsFixed(_amountDecimals).toArabicIndicDigits,
            style: _lineValueStyle,
          ),
        ],
      ),
    );
  }
}

bool _isInvalid(String text) =>
    text.trim().isNotEmpty && parseDecimalOrNull(text) == null;

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        // Filled + outlined like the app's cards: the raw Material underline
        // read as an empty row on the beige page.
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          filled: true,
          fillColor: colors.surface,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: colors.primary, width: 1.4),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
