import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/async_view.dart';
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
                CityPickerReady(:final results) => ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final city = results[i];
                      return ListTile(
                        title: Text(city.nameAr),
                        subtitle: Text(city.nameEn),
                        trailing: Text(city.id),
                        onTap: () async {
                          await context.read<CityPickerCubit>().persist(city);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    },
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
