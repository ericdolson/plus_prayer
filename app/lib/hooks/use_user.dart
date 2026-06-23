import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/models/user.dart';
import 'package:plusprayer/services/firebase.dart';

PPUser useUser() {
  final ppUser = useState<PPUser>(PPUser());

  useEffect(() {
    final unsubscribe = PPFirebase.subscribeToUser((user) {
      ppUser.value = user;
    });

    return unsubscribe;
  }, []);

  return ppUser.value;
}
