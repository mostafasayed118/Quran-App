import 'package:flutter/material.dart';

/// Shared by the GoRouter and by screens that need a "was covered, now
/// visible again" callback (Home's last-read and next-prayer cards).
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
