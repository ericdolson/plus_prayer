import 'package:flutter_hooks/flutter_hooks.dart';

/// [server], overridden by the value just chosen until its write settles, so a
/// switch moves at once. A failed write puts the server value back and calls
/// [onError].
(T, void Function(T)) useOptimistic<T>(
  T server,
  Future<void> Function(T value) write, {
  void Function(Object error)? onError,
}) {
  final pending = useState<(T,)?>(null);
  final context = useContext();
  final latest = useRef(0);

  void set(T value) {
    final mine = ++latest.value;
    pending.value = (value,);
    write(value).then<void>((_) {}, onError: (Object e) {
      if (context.mounted) onError?.call(e);
    }).whenComplete(() {
      // A later choice owns the override now.
      if (context.mounted && latest.value == mine) pending.value = null;
    });
  }

  final p = pending.value;
  return (p == null ? server : p.$1, set);
}
