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
          return Column(
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                key: const Key('tasbih_dial'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<TasbihCubit>().increment();
                },
                child: AnimatedScale(
                  scale: ready.reachedTarget ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primaryContainer,
                      border: Border.all(
                        color: colors.primary,
                        width: 3,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          ready.reachedTarget
                              ? Icons.check_circle
                              : Icons.touch_app_outlined,
                          color: colors.onPrimaryContainer,
                        ),
                        Text(
                          ready.count.toArabicIndic,
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer,
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
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final target in TasbihCubit.targets)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(target.toArabicIndic),
                        selected: ready.target == target,
                        onSelected: (_) => context
                            .read<TasbihCubit>()
                            .selectTarget(target),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.read<TasbihCubit>().reset(),
                icon: const Icon(Icons.refresh),
                label: Text(loc.tasbihReset),
              ),
              const SizedBox(height: 8),
              if (ready.reachedTarget)
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
