import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// True when the platform asks for reduced motion (iOS Reduce Motion,
/// Android "Remove animations"). Every animation checks this.
bool useReduceMotion() => MediaQuery.maybeDisableAnimationsOf(useContext()) ?? false;
