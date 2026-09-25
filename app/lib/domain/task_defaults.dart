import '../core/ids.dart';
import 'enums.dart';
import 'reminders.dart';

/// "Data padrão" of new tasks.
enum DefaultDate { none, today, tomorrow, dayAfterTomorrow, nextWeek }

/// Settings → Mais configurações: "Reconhecimento Inteligente" and "Padrão de Tarefas".
class TaskDefaults {
  const TaskDefaults({
    this.date = DefaultDate.none,
    this.timedReminder = ReminderPresets.onTime,
    this.allDayReminder,
    this.priority = Priority.none,
    this.listId = inboxListId,
    this.addAtTop = true,
    this.overdueAtTop = true,
    this.recognizeDates = true,
    this.removeDateText = true,
    this.removeTagText = true,
    this.durationMinutes,
    this.tagId,
    this.parseUrls = false,
  });

  final DefaultDate date;

  /// Default reminder of a task with a time ("Na hora") and of an all-day task (none); null = none.
  final String? timedReminder;
  final String? allDayReminder;
  final Priority priority;

  /// "Lista padrão": where tasks added outside a list go (smart lists, tags, filters).
  final String listId;

  /// "Adicionar nova tarefa": Topo / Fim da lista.
  final bool addAtTop;

  /// Position of the "Atrasadas" section: Topo / Fim.
  final bool overdueAtTop;

  /// "Reconhecimento de Data", "Remover textos nas tarefas" and "Reconhecimento de tag".
  final bool recognizeDates;
  final bool removeDateText;
  final bool removeTagText;

  /// "Duração padrão": a new task with a time lasts this long; null = no duration.
  final int? durationMinutes;

  /// "Tag padrão": new tasks get this tag; null = none.
  final String? tagId;

  /// "Análise de URL": a title that is only a link becomes the page's title. Off by
  /// default, since it reads the page from the internet.
  final bool parseUrls;

  TaskDefaults copyWith({
    DefaultDate? date,
    String? Function()? timedReminder,
    String? Function()? allDayReminder,
    Priority? priority,
    String? listId,
    bool? addAtTop,
    bool? overdueAtTop,
    bool? recognizeDates,
    bool? removeDateText,
    bool? removeTagText,
    int? Function()? durationMinutes,
    String? Function()? tagId,
    bool? parseUrls,
  }) => TaskDefaults(
    date: date ?? this.date,
    timedReminder: timedReminder == null ? this.timedReminder : timedReminder(),
    allDayReminder: allDayReminder == null ? this.allDayReminder : allDayReminder(),
    priority: priority ?? this.priority,
    listId: listId ?? this.listId,
    addAtTop: addAtTop ?? this.addAtTop,
    overdueAtTop: overdueAtTop ?? this.overdueAtTop,
    recognizeDates: recognizeDates ?? this.recognizeDates,
    removeDateText: removeDateText ?? this.removeDateText,
    removeTagText: removeTagText ?? this.removeTagText,
    durationMinutes: durationMinutes == null ? this.durationMinutes : durationMinutes(),
    tagId: tagId == null ? this.tagId : tagId(),
    parseUrls: parseUrls ?? this.parseUrls,
  );

  Map<String, Object?> toJson() => {
    'date': date.name,
    'timedReminder': timedReminder,
    'allDayReminder': allDayReminder,
    'priority': priority.code,
    'list': listId,
    'top': addAtTop,
    'overdueTop': overdueAtTop,
    'dates': recognizeDates,
    'removeDate': removeDateText,
    'removeTag': removeTagText,
    'duration': durationMinutes,
    'tag': tagId,
    'urls': parseUrls,
  };

  static TaskDefaults fromJson(Object? json) {
    const d = TaskDefaults();
    if (json is! Map<String, Object?>) return d;
    bool flag(String key, bool fallback) => json[key] is bool ? json[key]! as bool : fallback;
    String? trigger(String key, String? fallback) => json.containsKey(key) ? (json[key] is String ? json[key]! as String : null) : fallback;
    return TaskDefaults(
      date: DefaultDate.values.where((v) => v.name == json['date']).firstOrNull ?? d.date,
      timedReminder: trigger('timedReminder', d.timedReminder),
      allDayReminder: trigger('allDayReminder', d.allDayReminder),
      priority: Priority.values.where((p) => p.code == json['priority']).firstOrNull ?? d.priority,
      listId: json['list'] is String ? json['list']! as String : d.listId,
      addAtTop: flag('top', d.addAtTop),
      overdueAtTop: flag('overdueTop', d.overdueAtTop),
      recognizeDates: flag('dates', d.recognizeDates),
      removeDateText: flag('removeDate', d.removeDateText),
      removeTagText: flag('removeTag', d.removeTagText),
      durationMinutes: json['duration'] is int && (json['duration']! as int) > 0 ? json['duration']! as int : null,
      tagId: json['tag'] is String ? json['tag']! as String : null,
      parseUrls: flag('urls', d.parseUrls),
    );
  }
}

/// The day a [DefaultDate] means, from [today]; null for none.
DateTime? defaultDueDate(DefaultDate d, DateTime today) => switch (d) {
  DefaultDate.none => null,
  DefaultDate.today => today,
  DefaultDate.tomorrow => DateTime(today.year, today.month, today.day + 1),
  DefaultDate.dayAfterTomorrow => DateTime(today.year, today.month, today.day + 2),
  DefaultDate.nextWeek => DateTime(today.year, today.month, today.day + 7),
};
