import 'package:flutter/material.dart';

import 'models/cycle.dart';
import 'models/profile.dart';
import 'services/ambient_service.dart';
import 'services/profile_store.dart';

class AppState extends ChangeNotifier {
  AppState({ProfileStore? store, AmbientService? ambient})
      : _store = store ?? ProfileStore(),
        ambient = ambient ?? AmbientService();

  final ProfileStore _store;

  /// The Cozy Nook sound mixer, shared so sounds keep playing across tabs.
  final AmbientService ambient;
  Profile _profile = const Profile();
  bool _loaded = false;
  bool nightMode = false;

  Profile get profile => _profile;
  bool get loaded => _loaded;
  CycleStatus get cycle => CycleStatus.from(_profile.lastPeriodStart,
      cycleLength: _profile.cycleLength);

  Future<void> load() async {
    _profile = await _store.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(Profile profile) async {
    _profile = profile;
    notifyListeners();
    await _store.save(profile);
  }

  void toggleNight() {
    nightMode = !nightMode;
    notifyListeners();
  }

  Future<void> reset() async {
    await _store.clear();
    _profile = const Profile();
    notifyListeners();
  }
}

/// Makes [AppState] available to every screen.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
