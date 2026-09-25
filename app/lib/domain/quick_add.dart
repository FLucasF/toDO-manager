import '../core/clock.dart';
import 'enums.dart';

/// What the quick-add field recognized in a typed title (§2.9 "Reconhecimento Inteligente").
class QuickAdd {
  const QuickAdd({required this.title, this.priority, this.tagNames = const [], this.listName, this.dueDate, this.isAllDay = true});

  /// Title with the recognized tokens removed.
  final String title;
  final Priority? priority;
  final List<String> tagNames;

  /// Name of an existing list picked with `~` or `^`.
  final String? listName;

  /// Local due date (midnight when [isAllDay]).
  final DateTime? dueDate;
  final bool isAllDay;
}

/// Parses the quick-add syntax: `!prioridade`, `#tag`, `~lista`/`^lista` and dates/times in natural
/// language (PT-BR and English: "amanhã às 15h", "sexta", "25/09", "tomorrow 3pm").
/// [removeDateText] and [removeTagText] false keep the recognized date and `#tag` in the title
/// (Settings → Reconhecimento Inteligente).
QuickAdd parseQuickAdd(
  String input, {
  required DateTime now,
  List<String> listNames = const [],
  bool recognizeDates = true,
  bool removeDateText = true,
  bool removeTagText = true,
}) {
  var text = ' ${input.trim()} ';
  Priority? priority;
  String? listName;
  final tags = <String>[];

  // Priority: !alta !média !media !baixa !nenhuma (and English).
  text = text.replaceAllMapped(RegExp(r'(?<=\s)!(\p{L}+)(?=\s)', unicode: true), (m) {
    final p = _priorities[_fold(m.group(1)!)];
    if (p == null) return m.group(0)!;
    priority = p;
    return ' ';
  });

  // List: ~Nome or ^Nome, matching the longest existing list name.
  final sortedLists = [...listNames]..sort((a, b) => b.length.compareTo(a.length));
  for (final name in sortedLists) {
    final pattern = RegExp('(?<=\\s)[~^]${RegExp.escape(name)}(?=\\s)', caseSensitive: false);
    if (pattern.hasMatch(text)) {
      listName = name;
      text = text.replaceFirst(pattern, ' ');
      break;
    }
  }

  // Tags: #nome (letters, digits, _, -, /).
  text = text.replaceAllMapped(RegExp(r'(?<=\s)#([\p{L}\p{N}_/-]+)(?=\s)', unicode: true), (m) {
    tags.add(m.group(1)!);
    return removeTagText ? ' ' : m.group(0)!;
  });

  DateTime? due;
  var allDay = true;
  final beforeDates = text;
  if (recognizeDates) {
    final date = _extractDate(text, now);
    if (date != null) {
      text = date.rest;
      due = date.day;
    }
    final time = _extractTime(text);
    if (time != null) {
      text = time.rest;
      final base = due ?? startOfDay(now);
      var at = DateTime(base.year, base.month, base.day, time.hour, time.minute);
      // "às 9h" typed at 21h with no day means tomorrow at 9h.
      if (due == null && at.isBefore(now)) at = at.add(const Duration(days: 1));
      due = at;
      allDay = false;
    }
  }

  if (!removeDateText) text = beforeDates;
  return QuickAdd(
    title: text.replaceAll(RegExp(r'\s+'), ' ').trim(),
    priority: priority,
    tagNames: tags,
    listName: listName,
    dueDate: due,
    isAllDay: allDay,
  );
}

const _priorities = {
  'alta': Priority.high,
  'high': Priority.high,
  'media': Priority.medium,
  'medium': Priority.medium,
  'baixa': Priority.low,
  'low': Priority.low,
  'nenhuma': Priority.none,
  'none': Priority.none,
};

const _weekdays = {
  'segunda': DateTime.monday,
  'segunda-feira': DateTime.monday,
  'seg': DateTime.monday,
  'monday': DateTime.monday,
  'mon': DateTime.monday,
  'terca': DateTime.tuesday,
  'terca-feira': DateTime.tuesday,
  'ter': DateTime.tuesday,
  'tuesday': DateTime.tuesday,
  'tue': DateTime.tuesday,
  'quarta': DateTime.wednesday,
  'quarta-feira': DateTime.wednesday,
  'qua': DateTime.wednesday,
  'wednesday': DateTime.wednesday,
  'wed': DateTime.wednesday,
  'quinta': DateTime.thursday,
  'quinta-feira': DateTime.thursday,
  'qui': DateTime.thursday,
  'thursday': DateTime.thursday,
  'thu': DateTime.thursday,
  'sexta': DateTime.friday,
  'sexta-feira': DateTime.friday,
  'sex': DateTime.friday,
  'friday': DateTime.friday,
  'fri': DateTime.friday,
  'sabado': DateTime.saturday,
  'sab': DateTime.saturday,
  'saturday': DateTime.saturday,
  'sat': DateTime.saturday,
  'domingo': DateTime.sunday,
  'dom': DateTime.sunday,
  'sunday': DateTime.sunday,
  'sun': DateTime.sunday,
};

/// Lowercase without accents, so "Sábado", "sabado" and "SÁBADO" match.
String _fold(String s) => s.toLowerCase().replaceAllMapped(RegExp('[áàâãäéèêëíìîïóòôõöúùûüç]'), (m) => _accents[m.group(0)]!);

const _accents = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
};

typedef _DateMatch = ({DateTime day, String rest});
typedef _TimeMatch = ({int hour, int minute, String rest});

_DateMatch? _extractDate(String text, DateTime now) {
  final today = startOfDay(now);
  final folded = _fold(text);
  _DateMatch? found(RegExpMatch m, DateTime day) => (day: day, rest: '${text.substring(0, m.start)} ${text.substring(m.end)}');

  final relative = <String, int>{
    'depois de amanha': 2,
    'day after tomorrow': 2,
    'amanha': 1,
    'tomorrow': 1,
    'hoje': 0,
    'today': 0,
    'proxima semana': 7,
    'next week': 7,
  };
  for (final e in relative.entries) {
    final m = RegExp('(?<=\\s)${e.key}(?=\\s)').firstMatch(folded);
    if (m != null) return found(m, today.add(Duration(days: e.value)));
  }

  final month = RegExp(r'(?<=\s)(proximo mes|next month)(?=\s)').firstMatch(folded);
  if (month != null) return found(month, DateTime(today.year, today.month + 1, today.day));

  final inDays = RegExp(r'(?<=\s)(?:em|daqui a|in) (\d{1,3}) (?:dias?|days?)(?=\s)').firstMatch(folded);
  if (inDays != null) return found(inDays, today.add(Duration(days: int.parse(inDays.group(1)!))));

  // dd/mm or dd/mm/yyyy.
  final numeric = RegExp(r'(?<=\s)(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?(?=\s)').firstMatch(folded);
  if (numeric != null) {
    final d = int.parse(numeric.group(1)!), mo = int.parse(numeric.group(2)!);
    var y = numeric.group(3) == null ? today.year : int.parse(numeric.group(3)!);
    if (y < 100) y += 2000;
    if (mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
      var day = DateTime(y, mo, d);
      if (numeric.group(3) == null && day.isBefore(today)) day = DateTime(y + 1, mo, d);
      return found(numeric, day);
    }
  }

  // Weekday names: the next such day (today counts only when "hoje" is not implied: next occurrence).
  for (final e in _weekdays.entries) {
    final m = RegExp('(?<=\\s)(?:na |no |on |next )?${RegExp.escape(e.key)}(?=\\s)').firstMatch(folded);
    if (m != null) {
      var diff = (e.value - today.weekday) % 7;
      if (diff == 0) diff = 7;
      return found(m, today.add(Duration(days: diff)));
    }
  }
  return null;
}

_TimeMatch? _extractTime(String text) {
  final folded = _fold(text);
  // "às 15h", "as 15h30", "15:30", "at 3pm", "3pm", "3:30 pm".
  final patterns = [
    RegExp(r'(?<=\s)(?:as |at )?(\d{1,2}):(\d{2}) ?(am|pm)?(?=\s)'),
    RegExp(r'(?<=\s)(?:as |at )?(\d{1,2})h(\d{2})?(?=\s)'),
    RegExp(r'(?<=\s)(?:as |at )?(\d{1,2}) ?(am|pm)(?=\s)'),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(folded);
    if (m == null) continue;
    var hour = int.parse(m.group(1)!);
    var minute = 0;
    String? meridiem;
    if (p == patterns[0]) {
      minute = int.parse(m.group(2)!);
      meridiem = m.group(3);
    } else if (p == patterns[1]) {
      minute = m.group(2) == null ? 0 : int.parse(m.group(2)!);
    } else {
      meridiem = m.group(2);
    }
    if (meridiem == 'pm' && hour < 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) continue;
    return (hour: hour, minute: minute, rest: '${text.substring(0, m.start)} ${text.substring(m.end)}');
  }
  return null;
}

/// A time typed in the date picker's "Hora" field: "14:30", "14h30", "14h", "2pm", "1430", "9".
({int hour, int minute})? parseTime(String input) {
  final text = input.trim();
  final digits = RegExp(r'^(\d{1,2})(\d{2})?$').firstMatch(text);
  if (digits != null) {
    final hour = int.parse(digits.group(1)!);
    final minute = int.parse(digits.group(2) ?? '0');
    return hour > 23 || minute > 59 ? null : (hour: hour, minute: minute);
  }
  final match = _extractTime(' $text ');
  if (match == null || match.rest.trim().isNotEmpty) return null;
  return (hour: match.hour, minute: match.minute);
}

/// Quick-add token being typed at the cursor: `!`, `#`, `*`, `~` or `^` at the start of a
/// word, followed by the text typed so far.
class ActiveToken {
  const ActiveToken({required this.trigger, required this.query, required this.start, required this.end});

  final String trigger;
  final String query;

  /// Range of the token (trigger included) in the text.
  final int start;
  final int end;

  @override
  String toString() => 'ActiveToken($trigger$query @ $start-$end)';
}

const quickAddTriggers = '!#*~^';

/// The token under the cursor, or null when the cursor is not right after one.
ActiveToken? activeToken(String text, int cursor) {
  if (cursor < 0 || cursor > text.length) return null;
  var start = cursor;
  while (start > 0 && !RegExp(r'\s').hasMatch(text[start - 1])) {
    start--;
  }
  if (start == cursor || !quickAddTriggers.contains(text[start])) return null;
  return ActiveToken(trigger: text[start], query: text.substring(start + 1, cursor), start: start, end: cursor);
}

/// Replaces [token] with [insert] (which ends with a space); returns the text and the new cursor.
({String text, int cursor}) replaceToken(String text, ActiveToken token, String insert) {
  final rest = text.substring(token.end).replaceFirst(RegExp(r'^\S*'), '');
  final after = rest.startsWith(' ') ? rest.substring(1) : rest;
  return (text: '${text.substring(0, token.start)}$insert$after', cursor: token.start + insert.length);
}

/// Accent- and case-insensitive text for matching suggestions.
String foldForSearch(String s) => _fold(s);
