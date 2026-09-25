import '../core/clock.dart';
import 'import/imported_task.dart';
import 'recurrence.dart';

/// Kinds of subscribed calendars: Brazil's holidays (worked out here, no network)
/// or an iCalendar URL, downloaded and kept on the device.
enum SubscriptionKind { holidays, url }

/// A "Calendário assinado": read-only events shown in the calendar, Hoje and Próximos 7 dias.
class CalendarSubscription {
  const CalendarSubscription({required this.id, required this.name, required this.kind, this.url, this.color, this.visible = true, this.fetchedAt});

  final String id;
  final String name;
  final SubscriptionKind kind;
  final String? url;
  final String? color;

  /// Shown or hidden (the sidebar's eye).
  final bool visible;

  /// Last download of a URL calendar.
  final DateTime? fetchedAt;

  CalendarSubscription copyWith({String? name, String? url, String? color, bool? visible, DateTime? fetchedAt}) => CalendarSubscription(
    id: id,
    name: name ?? this.name,
    kind: kind,
    url: url ?? this.url,
    color: color ?? this.color,
    visible: visible ?? this.visible,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'url': url,
    'color': color,
    'visible': visible,
    'fetchedAt': fetchedAt?.toIso8601String(),
  };

  static CalendarSubscription? fromJson(Object? json) {
    if (json is! Map<String, Object?> || json['id'] is! String || json['name'] is! String) return null;
    final kind = SubscriptionKind.values.where((k) => k.name == json['kind']).firstOrNull;
    if (kind == null) return null;
    return CalendarSubscription(
      id: json['id']! as String,
      name: json['name']! as String,
      kind: kind,
      url: json['url'] is String ? json['url']! as String : null,
      color: json['color'] is String ? json['color']! as String : null,
      visible: json['visible'] != false,
      fetchedAt: json['fetchedAt'] is String ? DateTime.tryParse(json['fetchedAt']! as String) : null,
    );
  }
}

/// One occurrence of an event of a subscribed calendar. All-day events span local midnights
/// [start]..[end] (end day included).
class SubscribedEvent {
  const SubscribedEvent({
    required this.calendarId,
    required this.title,
    required this.start,
    required this.end,
    required this.isAllDay,
    this.description = '',
  });

  final String calendarId;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool isAllDay;
  final String description;

  bool touches(DateTime day) {
    final last = isAllDay
        ? startOfDay(end)
        : startOfDay(end.isAfter(start) && end == startOfDay(end) ? end.subtract(const Duration(minutes: 1)) : end);
    return !day.isBefore(startOfDay(start)) && !day.isAfter(last);
  }
}

/// Easter Sunday of [year] (Gregorian computus).
DateTime easterSunday(int year) {
  final a = year % 19, b = year ~/ 100, c = year % 100;
  final d = b ~/ 4, e = b % 4, f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4, k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

/// Brazil's national holidays and the usual optional days ("ponto facultativo") of [year], with names.
List<(DateTime, String)> brazilHolidays(int year) {
  final easter = easterSunday(year);
  DateTime fromEaster(int days) => DateTime(easter.year, easter.month, easter.day + days);
  return [
    (DateTime(year), 'Confraternização Universal'),
    (fromEaster(-48), 'Carnaval'),
    (fromEaster(-47), 'Carnaval'),
    (fromEaster(-46), 'Quarta-feira de Cinzas'),
    (fromEaster(-2), 'Sexta-feira Santa'),
    (easter, 'Páscoa'),
    (DateTime(year, 4, 21), 'Tiradentes'),
    (DateTime(year, 5), 'Dia do Trabalho'),
    (fromEaster(60), 'Corpus Christi'),
    (DateTime(year, 9, 7), 'Independência do Brasil'),
    (DateTime(year, 10, 12), 'Nossa Senhora Aparecida'),
    (DateTime(year, 11, 2), 'Finados'),
    (DateTime(year, 11, 15), 'Proclamação da República'),
    if (year >= 2024) (DateTime(year, 11, 20), 'Dia Nacional de Zumbi e da Consciência Negra'),
    (DateTime(year, 12, 25), 'Natal'),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
}

/// The events of [calendar] between [from] (inclusive) and [to] (exclusive): the holidays of those
/// years, or the events of the downloaded file ([icsEvents], from [parseICal]), repetitions included.
List<SubscribedEvent> subscribedEvents(CalendarSubscription calendar, DateTime from, DateTime to, {List<ImportedTask>? icsEvents}) {
  if (!calendar.visible) return const [];
  switch (calendar.kind) {
    case SubscriptionKind.holidays:
      return [
        for (var y = from.year; y <= to.year; y++)
          for (final (day, name) in brazilHolidays(y))
            if (!day.isBefore(from) && day.isBefore(to)) SubscribedEvent(calendarId: calendar.id, title: name, start: day, end: day, isAllDay: true),
      ];
    case SubscriptionKind.url:
      if (icsEvents == null) return const [];
      final List<SubscribedEvent> events = [];
      {
        for (final e in icsEvents) {
          final start = e.startDate ?? e.dueDate;
          if (start == null) continue;
          final end = e.dueDate ?? start;
          final length = end.difference(start);
          final starts = e.repeatRule == null ? [start] : occurrencesBetween(rule: e.repeatRule!, start: start, from: from.subtract(length), to: to);
          for (final s in starts) {
            final ev = SubscribedEvent(
              calendarId: calendar.id,
              title: e.title,
              start: s,
              end: s.add(length),
              isAllDay: e.isAllDay,
              description: e.content,
            );
            if (!startOfDay(ev.end).isBefore(from) && ev.start.isBefore(to)) events.add(ev);
          }
        }
      }
      return events..sort((a, b) => a.start.compareTo(b.start));
  }
}
