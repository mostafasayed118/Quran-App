import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/arabic_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import 'tasbih_cubit.dart';
import 'tasbih_state.dart';

class TasbihScreen extends StatelessWidget {
  const TasbihScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.tasbih)),
      body: BlocBuilder<TasbihCubit, TasbihState>(
        builder: (context, state) {
          final TasbihReady ready = switch (state) {
            TasbihReady() => state,
          };
          final colors = Theme.of(context).colorScheme;
          final done = ready.count >= ready.target;
          return Column(
            children: [
              const SizedBox(height: 16),
              _TasbihDial(ready: ready),
              const SizedBox(height: 20),
              _TargetChips(ready: ready),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.read<TasbihCubit>().reset(),
                icon: const Icon(Icons.refresh),
                label: Text(loc.tasbihReset),
              ),
              const SizedBox(height: 8),
              if (done)
                Text(
                  loc.azkarDone,
                  style: TextStyle(color: colors.secondary, fontSize: 13),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TasbihDial extends StatelessWidget {
  const _TasbihDial({required this.ready});

  final TasbihReady ready;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final done = ready.count >= ready.target;
    return AnimatedScale(
      scale: done ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        shape: CircleBorder(
          side: BorderSide(color: colors.primary, width: 3),
        ),
        color: colors.primaryContainer,
        child: InkWell(
          key: const Key('tasbih_dial'),
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<TasbihCubit>().increment();
          },
          child: SizedBox(
            width: 220,
            height: 220,
            child: _DialFace(ready: ready),
          ),
        ),
      ),
    );
  }
}

class _DialFace extends StatelessWidget {
  const _DialFace({required this.ready});

  final TasbihReady ready;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final done = ready.count >= ready.target;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          done ? Icons.check_circle : Icons.touch_app_outlined,
          color: colors.onPrimaryContainer,
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              ready.count.toArabicIndic,
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
        ),
        Text(
          '${loc.tasbihTarget}: ${ready.target.toArabicIndic}',
          style: TextStyle(
            fontSize: 13,
            color: colors.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _TargetChips extends StatelessWidget {
  const _TargetChips({required this.ready});

  final TasbihReady ready;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final target in TasbihCubit.targets)
          ChoiceChip(
            label: Text(target.toArabicIndic),
            selected: ready.target == target,
            onSelected: (_) {
              context.read<TasbihCubit>().selectTarget(target);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.tasbihTargetSet)),
              );
            },
          ),
      ],
    );
  }
}
