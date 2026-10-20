// Offline write queue (prayer-flow.md: praying without signal must not fail).
//
// - Every write is a serializable [PendingWrite] persisted BEFORE enqueue
//   returns, so a prayer survives the app being killed.
// - Sent strictly FIFO: a note edit can't overtake its prayer.
// - Transient failures (no network, timeouts) stop the flush and retry with
//   backoff; permanent ones (the server rejected the write) are dropped and
//   reported on [failures].
// - Writes are idempotent on the server (logPrayer's client id; note edits
//   are last-write-wins), so a resend after an ambiguous failure is safe.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

class PendingWrite {
  const PendingWrite({required this.id, required this.op, required this.args, this.attempts = 0});

  /// Client id (for logPrayer, the prayer's own UUID).
  final String id;

  /// Operation name, e.g. `logPrayer`, `updatePrayerNote`.
  final String op;
  final Map<String, Object?> args;
  final int attempts;

  PendingWrite retried() => PendingWrite(id: id, op: op, args: args, attempts: attempts + 1);

  Map<String, Object?> toJson() => {'id': id, 'op': op, 'args': args, 'attempts': attempts};

  factory PendingWrite.fromJson(Map<String, Object?> json) => PendingWrite(
        id: json['id'] as String,
        op: json['op'] as String,
        args: Map<String, Object?>.from(json['args'] as Map),
        attempts: json['attempts'] as int? ?? 0,
      );
}

/// Sends one write to the backend.
abstract interface class WriteSender {
  /// Throws [TransientWriteError] to retry later, [PermanentWriteError] to drop.
  Future<void> send(PendingWrite write);
}

class TransientWriteError implements Exception {
  const TransientWriteError([this.cause]);
  final Object? cause;

  @override
  String toString() => 'TransientWriteError($cause)';
}

class PermanentWriteError implements Exception {
  const PermanentWriteError(this.code, [this.message]);
  final String code;
  final String? message;

  @override
  String toString() => 'PermanentWriteError($code, $message)';
}

/// Where the queue lives on the device.
abstract interface class QueueStore {
  Future<List<PendingWrite>> load();
  Future<void> save(List<PendingWrite> writes);
}

class MemoryQueueStore implements QueueStore {
  List<PendingWrite> _writes = [];

  @override
  Future<List<PendingWrite>> load() async => [..._writes];

  @override
  Future<void> save(List<PendingWrite> writes) async => _writes = [...writes];
}

/// JSON in a single key-value entry (shared_preferences in the app).
class KeyValueQueueStore implements QueueStore {
  KeyValueQueueStore({required this.read, required this.write, this.key = 'pp.writeQueue.v1'});

  final Future<String?> Function(String key) read;
  final Future<void> Function(String key, String value) write;
  final String key;

  @override
  Future<List<PendingWrite>> load() async {
    final raw = await read(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return [for (final item in list) PendingWrite.fromJson(Map<String, Object?>.from(item as Map))];
  }

  @override
  Future<void> save(List<PendingWrite> writes) =>
      write(key, jsonEncode([for (final w in writes) w.toJson()]));
}

class QueueState {
  const QueueState({required this.pending, required this.sending});

  static const idle = QueueState(pending: [], sending: false);

  final List<PendingWrite> pending;
  final bool sending;
}

class WriteFailure {
  const WriteFailure(this.write, this.error);
  final PendingWrite write;
  final PermanentWriteError error;
}

class WriteQueue {
  WriteQueue({required QueueStore store, required WriteSender sender, Duration Function(int attempt)? backoff})
      : _store = store,
        _sender = sender,
        _backoff = backoff ?? _defaultBackoff;

  final QueueStore _store;
  final WriteSender _sender;
  final Duration Function(int attempt) _backoff;

  final _state = StreamController<QueueState>.broadcast();
  final _failures = StreamController<WriteFailure>.broadcast();
  List<PendingWrite> _pending = [];
  bool _sending = false;
  bool _loaded = false;
  Future<void>? _loading;
  Timer? _retry;

  static Duration _defaultBackoff(int attempt) =>
      Duration(seconds: math.min(300, 2 * math.pow(2, math.min(attempt, 8)).toInt()));

  QueueState get state => QueueState(pending: List.unmodifiable(_pending), sending: _sending);

  Stream<QueueState> watch() async* {
    await _ensureLoaded();
    yield state;
    yield* _state.stream;
  }

  Stream<WriteFailure> get failures => _failures.stream;

  /// Loads persisted writes and starts sending them.
  Future<void> start() async {
    await _ensureLoaded();
    unawaited(flush());
  }

  Future<void> enqueue(PendingWrite write) async {
    await _ensureLoaded();
    _pending = [..._pending, write];
    await _store.save(_pending);
    _emit();
    unawaited(flush());
  }

  /// Sends everything it can, in order. Safe to call any time (resume,
  /// reconnect); concurrent calls collapse into the running flush.
  Future<void> flush() async {
    await _ensureLoaded();
    if (_sending) return;
    _retry?.cancel();
    _sending = true;
    _emit();
    try {
      while (_pending.isNotEmpty) {
        final head = _pending.first;
        try {
          await _sender.send(head);
          _pending = _pending.sublist(1);
          await _store.save(_pending);
          _emit();
        } on PermanentWriteError catch (e) {
          _pending = _pending.sublist(1);
          await _store.save(_pending);
          _failures.add(WriteFailure(head, e));
          _emit();
        } catch (_) {
          // Transient (or unknown): keep it at the head and retry later.
          final retried = head.retried();
          _pending = [retried, ..._pending.sublist(1)];
          await _store.save(_pending);
          _retry = Timer(_backoff(retried.attempts), () => unawaited(flush()));
          break;
        }
      }
    } finally {
      _sending = false;
      _emit();
    }
  }

  Future<void> _ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _store.load().then((writes) {
      _pending = [...writes, ..._pending];
      _loaded = true;
    });
  }

  void _emit() {
    if (!_state.isClosed) _state.add(state);
  }

  Future<void> dispose() async {
    _retry?.cancel();
    await _state.close();
    await _failures.close();
  }
}
