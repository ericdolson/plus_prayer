import 'package:intl/intl.dart';

String abbreviatedNumber(int number) {
  return NumberFormat.compact().format(number);
}
