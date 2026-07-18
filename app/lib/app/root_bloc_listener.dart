import 'package:flutter/widgets.dart';

/// Single coordination point between global Blocs (contracts/blocs.md).
/// Blocs never import each other; every cross-feature effect is wired here.
class RootBlocListener extends StatelessWidget {
  const RootBlocListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Coordination listeners are added with US2 (T034) and US5 (T060).
    return child;
  }
}
