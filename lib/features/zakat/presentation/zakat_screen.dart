import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import 'zakat_cubit.dart';
import 'zakat_state.dart';

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
          final colors = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              SegmentedButton<bool>(
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
              ),
              const SizedBox(height: 10),
              _Field(label: loc.goldGrams, initial: ready.goldGrams, onChanged: context.read<ZakatCubit>().setGoldGrams),
              _Field(label: loc.silverGrams, initial: ready.silverGrams, onChanged: context.read<ZakatCubit>().setSilverGrams),
              _Field(label: loc.goldPrice, initial: ready.goldPrice, onChanged: context.read<ZakatCubit>().setGoldPrice),
              _Field(label: loc.silverPrice, initial: ready.silverPrice, onChanged: context.read<ZakatCubit>().setSilverPrice),
              _Field(label: loc.cash, initial: ready.cash, onChanged: context.read<ZakatCubit>().setCash),
              _Field(label: loc.debts, initial: ready.debts, onChanged: context.read<ZakatCubit>().setDebts),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _line(context, loc.zakatableLabel, ready.result.zakatable),
                      _line(context, loc.nisabLabel, ready.result.nisabValue),
                      const SizedBox(height: 8),
                      Text(
                        ready.result.due ? loc.zakatDue : loc.zakatNotDue,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: ready.result.due
                              ? colors.secondary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                      if (ready.result.due)
                        Text(
                          ready.result.amount.toStringAsFixed(2)
                              .toArabicIndicDigits,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        loc.zakatFootnote,
                        style: AppTheme.mutedFootnote(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _line(BuildContext context, String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            value.toStringAsFixed(2).toArabicIndicDigits,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.initial,
    required this.onChanged,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }
}
