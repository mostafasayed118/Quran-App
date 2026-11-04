import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds a live value on a periodic [interval], but only while the app is
/// in the foreground.
///
/// A clock that is on screen is worth one rebuild a second; a clock that is
/// behind another app is worth nothing, and the wakeup it costs is real. The
/// timer is cancelled on `inactive`/`paused`/`hidden` and restarted on
/// `resumed` — the same shape the prayer-times ticker uses.
///
/// [builder] receives the number of ticks that actually ran, starting at 0 and
/// continuing from where it stopped after a trip to the background. That count
/// is the observable a test can pin without depending on wall-clock time.
class LifecycleTicker extends StatefulWidget {
  const LifecycleTicker({
    super.key,
    required this.builder,
    this.interval = const Duration(seconds: 1),
  });

  /// Builds the tick-dependent subtree; [tick] increments once per [interval]
  /// spent in the foreground.
  final Widget Function(BuildContext context, int tick) builder;

  final Duration interval;

  @override
  State<LifecycleTicker> createState() => _LifecycleTickerState();
}

class _LifecycleTickerState extends State<LifecycleTicker>
    with WidgetsBindingObserver {
  Timer? _ticker;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A screen can mount while the app is already backgrounded (a notification
    // deep link, for example), so the binding's current state decides — not the
    // fact that initState ran.
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) _start();
  }

  void _start() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() => _tick++);
    });
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _stop();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    _stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _tick);
}
