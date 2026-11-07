import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Provides a route-scoped cubit and runs its one-time load from the widget
/// lifecycle.
///
/// Route cubits are side-effect free at construction: their data work (DB
/// reads, asset loads, plugin subscriptions) starts in [start]. This widget
/// calls [start] exactly once per created cubit, in `initState`, and closes
/// the cubit when the scope unmounts or [identity] changes — so no data work
/// ever starts from inside a `build()` frame and no stale cubit survives a
/// route-parameter change.
class RouteCubitScope<C extends Cubit<Object?>> extends StatefulWidget {
  const RouteCubitScope({
    super.key,
    required this.identity,
    required this.create,
    required this.start,
    required this.child,
  });

  /// Everything the cubit is built from: route parameters plus the route
  /// itself. A change discards the current cubit and mounts a fresh one, so
  /// no state can leak between two visits of the same route shape.
  final Object identity;

  /// Builds the cubit. Must not perform I/O.
  final C Function() create;

  /// Starts the cubit's load. Called once per created cubit.
  final Future<void> Function(C cubit) start;

  final Widget child;

  @override
  State<RouteCubitScope<C>> createState() => _RouteCubitScopeState<C>();
}

class _RouteCubitScopeState<C extends Cubit<Object?>>
    extends State<RouteCubitScope<C>> {
  late C _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = _mount();
  }

  @override
  void didUpdateWidget(RouteCubitScope<C> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.identity != oldWidget.identity) {
      unawaited(_cubit.close());
      _cubit = _mount();
    }
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<C>.value(value: _cubit, child: widget.child);
  }

  C _mount() {
    final cubit = widget.create();
    unawaited(widget.start(cubit));
    return cubit;
  }
}
