// Which backend the app talks to. Build with
//   flutter run --dart-define=PP_ENV=mock      (default)
//   flutter run --dart-define=PP_ENV=firebase  (build step 4)
// The UI never knows: it only sees the repository interfaces.

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock/mock_backend.dart';
import '../data/queue/queued_prayer_repository.dart';
import '../data/queue/write_queue.dart';
import '../state/providers.dart';

enum AppEnvironment {
  mock,
  firebase;

  static AppEnvironment get current =>
      const String.fromEnvironment('PP_ENV', defaultValue: 'mock') == 'firebase' ? firebase : mock;
}

/// The mock backend, when running on mock data (dev controls, tests).
final mockBackendProvider = Provider<MockBackend?>((_) => null);

Future<List<Override>> environmentOverrides(AppEnvironment env) async {
  switch (env) {
    case AppEnvironment.mock:
      final prefs = await SharedPreferences.getInstance();
      return mockOverrides(
        MockBackend(),
        store: KeyValueQueueStore(
          read: (key) async => prefs.getString(key),
          write: (key, value) => prefs.setString(key, value),
        ),
      );
    case AppEnvironment.firebase:
      // Build step 4: Firebase.initializeApp, anonymous auth, SQL Connect +
      // RTDB repositories, and a WriteSender over the generated SDK.
      throw UnimplementedError('The Firebase environment arrives with build step 4.');
  }
}

/// Wires every repository to [backend]. Tests call this with a memory store.
Future<List<Override>> mockOverrides(MockBackend backend, {QueueStore? store}) async {
  final queue = WriteQueue(store: store ?? MemoryQueueStore(), sender: MockWriteSender(backend));
  await queue.start();
  return [
    mockBackendProvider.overrideWithValue(backend),
    subjectRepositoryProvider.overrideWithValue(MockSubjectRepository(backend)),
    listRepositoryProvider.overrideWithValue(MockListRepository(backend)),
    userRepositoryProvider.overrideWithValue(MockUserRepository(backend)),
    liveRepositoryProvider.overrideWithValue(MockLiveRepository(backend)),
    writeQueueProvider.overrideWithValue(queue),
    prayerRepositoryProvider.overrideWithValue(QueuedPrayerRepository(queue)),
  ];
}
