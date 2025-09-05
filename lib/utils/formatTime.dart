String formatTime(DateTime time) {
  String hour = time.hour.toString().padLeft(2, '0');
  String minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatDateTime(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}_${dateTime.hour.toString().padLeft(2, '0')}-${dateTime.minute.toString().padLeft(2, '0')}-${dateTime.second.toString().padLeft(2, '0')}';
}




