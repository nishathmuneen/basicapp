const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _pad2(int value) => value.toString().padLeft(2, '0');

String toApiDateTimeString(DateTime dt) {
  return '${dt.year}-${_pad2(dt.month)}-${_pad2(dt.day)}T${_pad2(dt.hour)}:${_pad2(dt.minute)}';
}

String toApiDateString(DateTime dt) {
  return '${dt.year}-${_pad2(dt.month)}-${_pad2(dt.day)}';
}

String formatDateDisplay(String? recordedAt) {
  if (recordedAt == null || recordedAt.isEmpty) return '—';
  final datePart = recordedAt.split('T').first;
  final parts = datePart.split('-');
  if (parts.length != 3) return datePart;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null || month < 1 || month > 12) {
    return datePart;
  }
  return '$day ${_months[month - 1]} $year';
}

String formatShortDate(String? recordedAt) {
  if (recordedAt == null || recordedAt.isEmpty) return '';
  final datePart = recordedAt.split('T').first;
  final parts = datePart.split('-');
  if (parts.length != 3) return datePart;
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) {
    return datePart;
  }
  return '$day ${_months[month - 1]}';
}

String formatTimeDisplay(String? recordedAt) {
  if (recordedAt == null || recordedAt.isEmpty) return '—';
  final parts = recordedAt.split('T');
  final timePart = parts.length > 1 ? parts[1] : recordedAt;
  final hm = timePart.split(':');
  if (hm.length < 2) return timePart;
  final hour24 = int.tryParse(hm[0]);
  final minute = int.tryParse(hm[1].substring(0, 2));
  if (hour24 == null || minute == null) return timePart;
  final suffix = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:${_pad2(minute)} $suffix';
}

String formatWallTime(String hhmm) {
  return formatTimeDisplay('2000-01-01T$hhmm');
}

String formatDateTimeDisplay(String? recordedAt) {
  if (recordedAt == null || recordedAt.isEmpty) return 'No recordings yet';
  return '${formatDateDisplay(recordedAt)} at ${formatTimeDisplay(recordedAt)}';
}

String formatGlucoseValue(double? value) {
  if (value == null) return '—';
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

