import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/city_repository.dart';
import 'city_picker_cubit.dart';
import 'city_picker_state.dart';

class CityPickerScreen extends StatelessWidget {
  const CityPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.selectCity)),
      body: Column(
        children: [
          const _CitySearchField(),
          Expanded(
            child: BlocBuilder<CityPickerCubit, CityPickerState>(
              builder: (context, state) => switch (state) {
                CityPickerLoading() => const LoadingView(),
                CityPickerFailed() => errorPane(loc),
                CityPickerReady(
                  :final results,
                  :final locating,
                  :final selectedCityId,
                ) =>
                  Column(
                    children: [
                      _MyLocationTile(locating: locating),
                      const Divider(height: 1),
                      Expanded(
                        child: _CityResults(
                          results: results,
                          selectedCityId: selectedCityId,
                        ),
                      ),
                    ],
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CitySearchField extends StatelessWidget {
  const _CitySearchField();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 6),
      child: SearchField(
        hint: loc.searchCity,
        onChanged: (query) => context.read<CityPickerCubit>().search(query),
      ),
    );
  }
}

class _MyLocationTile extends StatelessWidget {
  const _MyLocationTile({required this.locating});

  final bool locating;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ListTile(
      leading: locating
          ? const SizedBox(
              width: AppSpacing.xl,
              height: AppSpacing.xl,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
      title: Text(locating ? loc.locating : loc.useMyLocation),
      onTap: locating ? null : () => _useMyLocation(context),
    );
  }

  Future<void> _useMyLocation(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<CityPickerCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final city = await cubit.locateNearest();
    if (!context.mounted) return;
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) return;
    if (city != null) {
      navigator.pop(true);
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(loc.locationUnavailable),
        action: SnackBarAction(
          label: loc.locationSettings,
          onPressed: () => cubit.openLocationSettings(),
        ),
      ));
    }
  }
}

class _CityResults extends StatelessWidget {
  const _CityResults({required this.results, required this.selectedCityId});

  final List<City> results;
  final String? selectedCityId;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return results.isEmpty
        ? EmptyState(loc.noResults)
        : ListView.builder(
            padding: EdgeInsets.only(bottom: appBottomInset(context)),
            itemCount: results.length,
            itemBuilder: (context, i) {
              final city = results[i];
              final isSelected = city.id == selectedCityId;
              return _ResultTile(city: city, isSelected: isSelected);
            },
          );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.city, required this.isSelected});

  final City city;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ListTile(
      selected: isSelected,
      title: Text(city.nameAr),
      subtitle: Text(city.nameEn),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              semanticLabel: loc.currentCity,
            )
          : null,
      onTap: () async {
        final persisted = await context.read<CityPickerCubit>().persist(city);
        if (!context.mounted) return;
        // While the picker is popping its subtree stays mounted, so the route
        // itself must be current before this continuation touches navigation.
        final route = ModalRoute.of(context);
        if (route?.isCurrent != true) return;
        if (persisted) {
          Navigator.of(context).pop(true);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.genericError)),
        );
      },
    );
  }
}
