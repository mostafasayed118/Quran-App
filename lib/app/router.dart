import 'package:go_router/go_router.dart';

import '../core/widgets/placeholder_screen.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, __) => const PlaceholderScreen(title: 'الرئيسية')),
      GoRoute(path: '/quran', builder: (_, __) => const PlaceholderScreen(title: 'القرآن الكريم')),
      GoRoute(path: '/recitation', builder: (_, __) => const PlaceholderScreen(title: 'التلاوات')),
      GoRoute(path: '/library', builder: (_, __) => const PlaceholderScreen(title: 'المكتبة')),
      GoRoute(path: '/prayer-times', builder: (_, __) => const PlaceholderScreen(title: 'مواقيت الصلاة')),
      GoRoute(path: '/qibla', builder: (_, __) => const PlaceholderScreen(title: 'القبلة')),
      GoRoute(path: '/azkar', builder: (_, __) => const PlaceholderScreen(title: 'الأذكار')),
      GoRoute(path: '/tasbih', builder: (_, __) => const PlaceholderScreen(title: 'السبحة')),
      GoRoute(path: '/duas', builder: (_, __) => const PlaceholderScreen(title: 'الأدعية والرقية')),
      GoRoute(path: '/worship', builder: (_, __) => const PlaceholderScreen(title: 'تتبع العبادات')),
      GoRoute(path: '/zakat', builder: (_, __) => const PlaceholderScreen(title: 'الزكاة')),
      GoRoute(path: '/hijri', builder: (_, __) => const PlaceholderScreen(title: 'التقويم الهجري')),
      GoRoute(path: '/asma', builder: (_, __) => const PlaceholderScreen(title: 'أسماء الله الحسنى')),
      GoRoute(path: '/settings', builder: (_, __) => const PlaceholderScreen(title: 'الإعدادات')),
    ],
  );
}
