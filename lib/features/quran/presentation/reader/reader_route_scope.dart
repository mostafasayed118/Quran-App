import 'package:flutter/material.dart';

import '../../../../core/routing/route_cubit_scope.dart';
import 'reader_cubit.dart';

/// Scopes a [ReaderCubit] to one `(surah, ayah)` pair.
///
/// The full reader route and the workspace pane share it, so a selection
/// change closes the previous cubit and starts the next one with the same
/// lifecycle guarantees in both presentations.
class ReaderRouteScope extends StatelessWidget {
  /// Creates the scope; [create] must be side-effect free.
  const ReaderRouteScope({
    super.key,
    required this.surah,
    required this.ayah,
    required this.create,
    required this.child,
  });

  /// The selected surah.
  final int surah;

  /// The initial ayah; 0 starts at the surah's first ayah.
  final int ayah;

  /// Builds the cubit; [RouteCubitScope] calls `start` once per identity.
  final ReaderCubit Function() create;

  /// The reader content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RouteCubitScope<ReaderCubit>(
      identity: (surah, ayah),
      create: create,
      start: (cubit) => cubit.start(),
      child: child,
    );
  }
}
