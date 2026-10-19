import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

TimerState useTimer(int seconds, {bool start = false}) {
  return use(_TimerHook(seconds, start));
}

class TimerState {
  final int secondsRemaining;
  final bool complete;
  final void Function() startTimer;

  TimerState(this.secondsRemaining, this.complete, this.startTimer);
}

// Custom Hook Class
class _TimerHook extends Hook<TimerState> {
  final int seconds;
  final bool start;

  const _TimerHook(this.seconds, this.start);

  @override
  _TimerHookState createState() => _TimerHookState();
}

class _TimerHookState extends HookState<TimerState, _TimerHook> {
  late int secondsRemaining;
  bool isRunning = false;
  bool complete = false;
  Timer? timer;

  @override
  void initHook() {
    super.initHook();
    secondsRemaining = hook.seconds;

    if (hook.start) {
      startTimer();
    }
  }

  void startTimer() {
    if (isRunning) return;

    isRunning = true;
    complete = false;
    secondsRemaining = hook.seconds;

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        secondsRemaining--;

        if (secondsRemaining == 0) {
          timer.cancel();
          isRunning = false;
          complete = true;
        }
      });
    });
  }

  @override
  TimerState build(BuildContext context) {
    return TimerState(secondsRemaining, complete, startTimer);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
