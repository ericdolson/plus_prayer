import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/services/firebase.dart';

import '../models/name.dart';

UseNameResponse useName(String id) {
  final useNameResponse = useState(UseNameResponse(loading: true));

  useEffect(() {
    final subscription = FirebaseFirestore.instance
        .collection(Collections.names.name)
        .doc(id)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) {
        useNameResponse.value = UseNameResponse(error: 'Name does not exist', loading: false);
      } else {
        useNameResponse.value = UseNameResponse(
          name: Name.fromFirestore(doc),
          loading: false,
        );
      }
    });

    return subscription.cancel;
  }, [id]);

  return useNameResponse.value;
}

class UseNameResponse {
  final Name? name;
  final String? error;
  late final bool loading;

  UseNameResponse({
    this.name,
    this.error,
    bool? loading,
  }) {
    this.loading = loading ?? true;
  }
}
