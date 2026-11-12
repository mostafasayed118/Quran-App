part of '../router.dart';

/// The prayer stack and the worship tabs: prayer times, qada, Ramadan, tasbih,
/// tracker, qibla, azkar and duas.
List<RouteBase> _prayerRoutes() => [
      GoRoute(
        path: AppRoutes.cityPicker,
        builder: (_, __) => RouteCubitScope<CityPickerCubit>(
          create: () => CityPickerCubit(
            cityRepo: getIt<CityRepository>(),
            location: getIt<LocationService>(),
          ),
          identity: AppRoutes.cityPicker,
          start: (cubit) => cubit.start(),
          child: const CityPickerScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.prayerSettings,
        builder: (_, __) => RouteCubitScope<PrayerConfigCubit>(
          create: () => PrayerConfigCubit(
            source: getIt<PrayerConfigSource>(),
            preAdhanCanceller: getIt<PreAdhanCanceller>(),
          ),
          identity: AppRoutes.prayerSettings,
          start: (cubit) => cubit.start(),
          child: const PrayerConfigScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.prayerMonth,
        builder: (_, __) => RouteCubitScope<PrayerMonthCubit>(
          create: () => PrayerMonthCubit(
            city: getIt<CitySource>(),
            prayer: getIt<PrayerTimesPort>(),
          ),
          identity: AppRoutes.prayerMonth,
          start: (cubit) => cubit.start(),
          child: const PrayerMonthScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.qibla,
        builder: (_, __) => RouteCubitScope<QiblaCubit>(
          create: () => QiblaCubit(
            city: getIt<CitySource>(),
            qibla: getIt<QiblaService>(),
            heading: getIt<HeadingService>(),
            calibration: getIt<CompassCalibration>(),
          ),
          identity: AppRoutes.qibla,
          start: (cubit) => cubit.start(),
          child: const QiblaScreen(),
        ),
      ),
    ];

List<RouteBase> _worshipRoutes() => [
      GoRoute(
        path: AppRoutes.tasbih,
        builder: (_, __) => RouteCubitScope<TasbihCubit>(
          create: () => TasbihCubit(repo: getIt<TasbihRepository>()),
          identity: AppRoutes.tasbih,
          start: (cubit) => cubit.start(),
          child: const TasbihScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.duas,
        builder: (_, __) => RouteCubitScope<DuasCubit>(
          create: () => DuasCubit(
            duas: getIt<DuaRepository>(),
            ruqyah: getIt<RuqyahRepository>(),
            ayahs: getIt<AyahLookup>(),
          ),
          identity: AppRoutes.duas,
          start: (cubit) => cubit.start(),
          child: const DuasScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.worship,
        builder: (_, __) => RouteCubitScope<TrackerCubit>(
          create: () => TrackerCubit(
            repo: getIt<PrayerLogRepository>(),
            khatma: getIt<KhatmaRepository>(),
          ),
          identity: AppRoutes.worship,
          start: (cubit) => cubit.start(),
          child: const TrackerScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.ramadan,
        builder: (_, __) => RouteCubitScope<RamadanCubit>(
          create: () => RamadanCubit(
            city: getIt<CitySource>(),
            prayer: getIt<PrayerTimesPort>(),
            calendar: getIt<RamadanCalendar>(),
          ),
          identity: AppRoutes.ramadan,
          start: (cubit) => cubit.start(),
          child: const RamadanScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.qada,
        builder: (_, __) => RouteCubitScope<QadaCubit>(
          create: () => QadaCubit(source: getIt<QadaSource>()),
          identity: AppRoutes.qada,
          start: (cubit) => cubit.start(),
          child: const QadaScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.zakat,
        builder: (_, __) => BlocProvider<ZakatCubit>(
          create: (_) => ZakatCubit(),
          child: const ZakatScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.hijri,
        builder: (_, __) => RouteCubitScope<HijriCubit>(
          create: () => HijriCubit(
            service: getIt<HijriService>(),
            offset: getIt<HijriOffsetSource>(),
            locale: () => getIt<AppLocaleController>().language.code,
          ),
          identity: AppRoutes.hijri,
          start: (cubit) => cubit.start(),
          child: const HijriScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.asma,
        builder: (_, __) => RouteCubitScope<AsmaCubit>(
          create: () => AsmaCubit(repository: getIt<AsmaRepository>()),
          identity: AppRoutes.asma,
          start: (cubit) => cubit.start(),
          child: const AsmaScreen(),
        ),
      ),
    ];
