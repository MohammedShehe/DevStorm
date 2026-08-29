/// Parse server datetime as **local wall-clock** (ignores erroneous trailing Z).
DateTime parseServerDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  var s = value.toString().trim();
  // Strip timezone markers so Dart treats as local
  s = s.replaceAll('Z', '').replaceAll(RegExp(r'[+-]\d{2}:\d{2}$'), '');
  s = s.replaceFirst('T', ' ');
  if (s.contains('.')) {
    s = s.split('.').first;
  }
  // Ensure parseable
  s = s.replaceAll('/', '-');
  try {
    return DateTime.parse(s);
  } catch (_) {
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatDateYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
