import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  String yMMMd(String locale) => DateFormat.yMMMd(locale).format(this);

  String formatHM() => '${hour.toTwo()}:${minute.toTwo()}';
}

extension IntX on int {
  String formatMinutes() => '${(this ~/ 60).toTwo()}:${(this % 60).toTwo()}';
  String toTwo() => toString().padLeft(2, '0');
}
