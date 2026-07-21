import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  String yMMMd(String locale) => DateFormat.yMMMd(locale).format(this);

  String displayHM() => '${hour.toTwo()}:${minute.toTwo()}';
}

extension IntX on int {
  String toTwo() => toString().padLeft(2, '0');
}
