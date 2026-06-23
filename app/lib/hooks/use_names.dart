import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/services/firebase.dart';

import '../models/name.dart';

List<Name> useNames() {
  final names = useState<List<Name>>([]);

  useEffect(() {
    final unsubscribe = PPFirebase.subscribeToNames((namesList) {
      names.value = namesList;
    });

    return unsubscribe;
  }, []);

  return names.value;
}
