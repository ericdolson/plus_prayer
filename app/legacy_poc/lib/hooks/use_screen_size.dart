import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Size useScreenSize() {
  final context = useContext();
  return useMemoized(() => MediaQuery.of(context).size, [context]);
}
