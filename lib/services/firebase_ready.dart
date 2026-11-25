import 'package:firebase_core/firebase_core.dart';

/// True once Firebase has been set up for this build. Never throws, so the
/// app keeps working offline and in the web preview without Firebase.
bool get firebaseReady {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}
