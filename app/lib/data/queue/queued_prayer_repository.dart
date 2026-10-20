// PrayerRepository over the write queue. Shared by every environment: only
// the queue's WriteSender differs (mock backend now, SQL Connect at step 4).

import 'dart:async';

import '../../domain/models/prayer.dart';
import '../repositories/repositories.dart';
import 'write_queue.dart';

abstract final class WriteOps {
  static const logPrayer = 'logPrayer';
  static const updatePrayerNote = 'updatePrayerNote';
}

class QueuedPrayerRepository implements PrayerRepository {
  QueuedPrayerRepository(this._queue);

  final WriteQueue _queue;
  final _changes = StreamController<List<NewPrayer>>.broadcast();
  List<NewPrayer> _local = [];
  Future<void>? _seeding;

  /// Prayers still waiting in the persisted queue (e.g. logged offline before
  /// the app was killed) count as local from the start.
  Future<void> _seed() => _seeding ??= _queue.watch().first.then((state) {
        final queued = [
          for (final w in state.pending)
            if (w.op == WriteOps.logPrayer) NewPrayer.fromJson(w.args),
        ];
        _local = [...queued, ..._local.where((p) => !queued.any((q) => q.id == p.id))];
      });

  @override
  Future<void> logPrayer(NewPrayer prayer) async {
    await _seed();
    _local = [..._local, prayer];
    _changes.add(_local);
    await _queue.enqueue(PendingWrite(id: prayer.id, op: WriteOps.logPrayer, args: prayer.toJson()));
  }

  @override
  Future<void> updateNote(String prayerId, String? note) async {
    await _seed();
    await _queue.enqueue(PendingWrite(
      id: 'note:$prayerId:${DateTime.now().microsecondsSinceEpoch}',
      op: WriteOps.updatePrayerNote,
      args: {'id': prayerId, 'note': note},
    ));
  }

  @override
  Stream<List<NewPrayer>> watchLocalPrayers() async* {
    await _seed();
    yield _local;
    yield* _changes.stream;
  }

  Future<void> dispose() => _changes.close();
}
