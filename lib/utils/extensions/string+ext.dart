import 'package:intl/intl.dart';

extension FormattedDateExtension on String {
  String formatToCustomDate() {
    DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(this);
    return DateFormat('dd MMM yyyy').format(parsedDate);
  }
}