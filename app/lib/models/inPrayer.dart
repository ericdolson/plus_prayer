import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plusprayer/models/prayer.dart';

import '../services/firebase.dart';

class InPrayer {
  DateTime startedAt;

  InPrayer({required this.startedAt});

  factory InPrayer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final DateTime? startedAt = data['startedAt']?.toDate();

    return InPrayer(startedAt: startedAt ?? DateTime.now());
  }

  Map<String, dynamic> toFirestore() {
    return {
      'startedAt': startedAt,
    };
  }
}
