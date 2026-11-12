part of '../router.dart';

/// Settings and the first-run flow that leads to it, plus the principles
/// and update surfaces that hang off them.
List<RouteBase> _settingsRoutes() => [
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => MultiBlocProvider(
          providers: [
            BlocProvider<BackupCubit>(
              create: (_) => BackupCubit(service: getIt<BackupService>()),
            ),
          ],
          child: RouteCubitScope<SettingsCubit>(
            create: () => SettingsCubit(
              settings: getIt<ReminderSettingsPort>(),
              prayerSettings: getIt<PrayerReminderSettingsPort>(),
              city: getIt<CitySource>(),
              prayer: getIt<PrayerTimesPort>(),
              scheduler: getIt<ReminderSchedulerPort>(),
              adhanPrefs: getIt<AdhanPreferences>(),
            ),
            identity: AppRoutes.settings,
            start: (cubit) => cubit.start(),
            child: SettingsScreen(
              backupSection: const BackupSection(),
              locale: getIt<AppLocaleController>(),
              theme: getIt<AppThemeController>(),
              // Resolved at route construction, not from SettingsScreen's
              // build(); tests that never configure the locator get null and
              // the screen simply omits the advisory readout.
              reminderDiagnostics: getIt.isRegistered<ReminderDiagnostics>()
                  ? getIt<ReminderDiagnostics>()
                  : null,
              reminderApplyHealth: getIt.isRegistered<ReminderApplyHealth>()
                  ? getIt<ReminderApplyHealth>()
                  : null,
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.adhanPicker,
        builder: (_, __) => RouteCubitScope<AdhanPickerCubit>(
          create: () => AdhanPickerCubit(
            prefs: getIt<AdhanPreferences>(),
            player: getIt<AdhanPlayer>(),
            // The picker only needs "the schedule changed", not the city and
            // prayer machinery behind it.
            reschedule: () => getIt<ReminderSettingsPort>().reschedule(
              city: getIt<CitySource>(),
              prayer: getIt<PrayerTimesPort>(),
              scheduler: getIt<ReminderSchedulerPort>(),
            ),
          ),
          identity: AppRoutes.adhanPicker,
          start: (cubit) => cubit.start(),
          child: const AdhanPickerScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.principles,
        builder: (_, __) => const PrinciplesScreen(),
      ),
    ];

List<RouteBase> _onboardingRoutes() => [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => RouteCubitScope<OnboardingCubit>(
          create: () => OnboardingCubit(
            city: getIt<CitySource>(),
            status: getIt<OnboardingStatusSource>(),
            reminders: getIt<ReminderSchedulerPort>(),
          ),
          identity: AppRoutes.onboarding,
          start: (cubit) => cubit.start(),
          child: const OnboardingScreen(),
        ),
        routes: [
          GoRoute(
            path: 'city',
            builder: (_, __) => RouteCubitScope<CityPickerCubit>(
              create: () => CityPickerCubit(
                cityRepo: getIt<CityRepository>(),
                location: getIt<LocationService>(),
              ),
              identity: AppRoutes.onboardingCity,
              start: (cubit) => cubit.start(),
              child: const CityPickerScreen(),
            ),
          ),
        ],
      ),
    ];
