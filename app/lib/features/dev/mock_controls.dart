// Debug-only scenario controls for the mock backend (long-press the list row
// in a debug build). Developer tooling, not product UI — strings here are
// intentionally not in the ARB file.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../data/mock/mock_backend.dart';
import '../../domain/models/live.dart';
import '../../theme/pp_theme.dart';

Future<void> showMockControls(BuildContext context, MockBackend backend) => showModalBottomSheet<void>(
      context: context,
      builder: (_) => _MockControls(backend: backend),
    );

class _MockControls extends HookWidget {
  const _MockControls({required this.backend});

  final MockBackend backend;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final online = useState(backend.online);
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(pp.space.lg, 0, pp.space.lg, pp.space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mock backend', style: context.text.titleLarge),
            SwitchListTile(
              title: const Text('Online'),
              subtitle: const Text('Off: prayers queue; adding fails'),
              value: online.value,
              onChanged: (v) => online.value = backend.online = v,
            ),
            ListTile(
              title: const Text('List closes in 5 minutes'),
              onTap: () => backend.setClosesAt(DateTime.now().add(const Duration(minutes: 5))),
            ),
            ListTile(title: const Text('Clear closesAt'), onTap: () => backend.setClosesAt(null)),
            ListTile(
              title: const Text('Live: busy'),
              onTap: () => backend.setStats(const LiveStats(prayingNow: 213, prayedLastHour: 640, prayedToday: 4113)),
            ),
            ListTile(
              title: const Text('Live: quiet hour'),
              onTap: () => backend.setStats(const LiveStats(prayingNow: 3, prayedLastHour: 38, prayedToday: 412)),
            ),
            ListTile(
              title: const Text('Live: nearly empty'),
              onTap: () => backend.setStats(const LiveStats(prayingNow: 1, prayedLastHour: 2, prayedToday: 6)),
            ),
          ],
        ),
      ),
    );
  }
}
