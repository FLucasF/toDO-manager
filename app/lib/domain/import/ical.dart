import 'imported_task.dart';

/// Reads the to-dos (VTODO) and events (VEVENT) of an iCalendar file ("Importar arquivo iCal", Fluxos
/// §27.10) as tasks: SUMMARY, DESCRIPTION, DTSTART, DUE / DTEND, RRULE, STATUS, COMPLETED, PRIORITY,
/// CATEGORIES and the VALARM triggers. Throws [FormatException] when there is no calendar.
List<ImportedTask> parseICal(String text) {
  // Long lines are folded: a line starting with a space or tab continues the previous one.
  final lines = <String>[];
  for (final raw in text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n')) {
    if ((raw.startsWith(' ') || raw.startsWith('\t')) && lines.isNotEmpty) {
      lines[lines.length - 1] += raw.substring(1);
    } else if (raw.isNotEmpty) {
      lines.add(raw);
    }
  }
  if (!lines.any((l) => l.toUpperCase() == 'BEGIN:VCALENDAR')) throw const FormatException('not an iCalendar file');

  final tasks = <ImportedTask>[];
  Map<String, (String, Map<String, String>)>? props;
  final alarms = <String>[];
  var inAlarm = false;
  var isEvent = false;
  for (final line in lines) {
    final upper = line.toUpperCase();
    if (upper == 'BEGIN:VTODO' || upper == 'BEGIN:VEVENT') {
      props = {};
      alarms.clear();
      isEvent = upper == 'BEGIN:VEVENT';
      continue;
    }
    if (upper == 'BEGIN:VALARM') {
      inAlarm = true;
      continue;
    }
    if (upper == 'END:VALARM') {
      inAlarm = false;
      continue;
    }
    if ((upper == 'END:VTODO' || upper == 'END:VEVENT') && props != null) {
      tasks.add(_task(props, alarms, isEvent: isEvent));
      props = null;
      continue;
    }
    if (props == null) continue;
    final colon = _colon(line);
    if (colon < 0) continue;
    final head = line.substring(0, colon).split(';');
    final name = head.first.toUpperCase();
    final params = {
      for (final p in head.skip(1))
        if (p.contains('=')) p.substring(0, p.indexOf('=')).toUpperCase(): p.substring(p.indexOf('=') + 1),
    };
    final value = line.substring(colon + 1);
    if (inAlarm) {
      if (name == 'TRIGGER') alarms.add(value.trim());
    } else {
      props.putIfAbsent(name, () => (value, params));
    }
  }
  return tasks;
}

/// The colon between the property and its value (not one inside a quoted parameter).
int _colon(String line) {
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    if (line[i] == '"') quoted = !quoted;
    if (line[i] == ':' && !quoted) return i;
  }
  return -1;
}

String _unescape(String v) => v.replaceAll(r'\n', '\n').replaceAll(r'\N', '\n').replaceAll(r'\,', ',').replaceAll(r'\;', ';').replaceAll(r'\\', r'\');

ImportedTask _task(Map<String, (String, Map<String, String>)> p, List<String> alarms, {required bool isEvent}) {
  final start = _date(p['DTSTART']);
  var end = _date(p[isEvent ? 'DTEND' : 'DUE']) ?? start;
  final allDay = p['DTSTART']?.$2['VALUE']?.toUpperCase() == 'DATE' || (start == null && p['DUE']?.$2['VALUE']?.toUpperCase() == 'DATE');
  // An all-day event's DTEND is the day after its last day.
  if (isEvent && allDay && end != null && start != null && end.isAfter(start)) end = end.subtract(const Duration(days: 1));
  final status = p['STATUS']?.$1.trim().toUpperCase();
  final priority = int.tryParse(p['PRIORITY']?.$1.trim() ?? '');
  final rrule = p['RRULE']?.$1.trim();
  return ImportedTask(
    title: _unescape(p['SUMMARY']?.$1 ?? '').trim(),
    content: _unescape(p['DESCRIPTION']?.$1 ?? '').trim(),
    tags: [
      for (final c in (p['CATEGORIES']?.$1 ?? '').split(','))
        if (_unescape(c).trim().isNotEmpty) _unescape(c).trim().replaceAll(' ', '_'),
    ],
    startDate: start,
    dueDate: end,
    isAllDay: allDay || (start == null && end == null),
    reminders: [for (final a in alarms) ...triggersIn(a)],
    repeatRule: rrule == null || rrule.isEmpty ? null : rrule,
    // iCalendar: 1-4 high, 5 medium, 6-9 low, 0 none.
    priority: switch (priority) {
      null || 0 => 0,
      <= 4 => 5,
      5 => 3,
      _ => 1,
    },
    status: switch (status) {
      'COMPLETED' => ImportedStatus.completed,
      'CANCELLED' => ImportedStatus.wontDo,
      _ => ImportedStatus.open,
    },
    completedAt: _date(p['COMPLETED']),
  );
}

/// `20260925` (a day), `20260925T090000Z` (UTC) or `20260925T090000` (local; TZID is taken as local).
DateTime? _date((String, Map<String, String>)? prop) {
  if (prop == null) return null;
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$').firstMatch(prop.$1.trim());
  if (m == null) return null;
  int n(int g) => int.tryParse(m.group(g) ?? '') ?? 0;
  if (m.group(4) == null) return DateTime(n(1), n(2), n(3));
  return m.group(7) != null ? DateTime.utc(n(1), n(2), n(3), n(4), n(5), n(6)).toLocal() : DateTime(n(1), n(2), n(3), n(4), n(5), n(6));
}
