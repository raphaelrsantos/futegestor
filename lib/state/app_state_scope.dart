import 'package:flutter/widgets.dart';
import 'app_state.dart';

/// AppStateScope is a lightweight replacement for the provider package
/// using InheritedNotifier to propagate [AppState] changes.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  /// Subscribe to AppState changes (equivalent to context.watch<AppState>()).
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope.of() called with no AppStateScope in context');
    return scope!.notifier!;
  }

  /// Read AppState without subscribing (equivalent to context.read<AppState>()).
  static AppState read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppStateScope>();
    final widget = element?.widget as AppStateScope?;
    assert(widget != null, 'AppStateScope.read() called with no AppStateScope in context');
    return widget!.notifier!;
  }
}

extension AppStateContextX on BuildContext {
  AppState appWatch() => AppStateScope.of(this);
  AppState appRead() => AppStateScope.read(this);
}
