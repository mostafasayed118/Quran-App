import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: SearchField(
              hint: loc.searchCity,
              onChanged: (query) =>
                  context.read<CityPickerCubit>().search(query),
            ),
          ),
          Expanded(
            child: BlocBuilder<CityPickerCubit, CityPickerState>(
              builder: (context, state) => switch (state) {
                CityPickerLoading() => const LoadingView(),
                CityPickerFailed() =>
                  errorPane(loc, 'city picker load failed', 'city_picker'),
                CityPickerReady(:final results, :final locating) => Column(
                    children: [
                      ListTile(
                        leading: locating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        title:
                            Text(locating ? loc.locating : loc.useMyLocation),
                        onTap: locating ? null : () => _useMyLocation(context),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: results.isEmpty
                            ? EmptyState(loc.noResults)
                            : ListView.builder(
                                itemCount: results.length,
                                itemBuilder: (context, i) {
                                  final city = results[i];
                                  return ListTile(
                                    title: Text(city.nameAr),
                                    subtitle: Text(city.nameEn),
                                    trailing: Text(city.id),
                                    onTap: () async {
                                      await context
                                          .read<CityPickerCubit>()
                                          .persist(city);
                                      if (context.mounted) {
                                        Navigator.of(context).pop(true);
                                      }
                                    },
                                  );
                                },
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

  Future<void> _useMyLocation(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<CityPickerCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final city = await cubit.locateNearest();
    if (city != null) {
      navigator.pop(true);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(loc.locationUnavailable)));
    }
  }
}
