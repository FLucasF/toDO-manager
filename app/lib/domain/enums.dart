/// Domain enums stored with TickTick's own numeric/text codes, so the
/// database and a future TickTick backup import need no translation.
library;

/// Enum persisted by a TickTick code ([C] is `int` or `String`).
abstract interface class Coded<C> {
  C get code;
}

T _byCode<T extends Enum, C>(List<T> values, C code, C Function(T) codeOf, String what) =>
    values.firstWhere((v) => codeOf(v) == code, orElse: () => throw FormatException('unknown $what: $code'));

/// Task priority; the checkbox border color follows it.
enum Priority implements Coded<int> {
  none(0),
  low(1),
  medium(3),
  high(5);

  const Priority(this.code);

  @override
  final int code;

  static Priority fromCode(int code) => _byCode(values, code, (p) => p.code, 'priority');
}

/// Task status. "Won't do" is a status of its own, not a deletion.
enum TaskStatus implements Coded<int> {
  open(0),
  completed(2),
  wontDo(-1);

  const TaskStatus(this.code);

  @override
  final int code;

  static TaskStatus fromCode(int code) => _byCode(values, code, (s) => s.code, 'task status');
}

/// Item kind: plain task, task in checklist mode, or note.
enum TaskKind implements Coded<String> {
  text('TEXT'),
  checklist('CHECKLIST'),
  note('NOTE');

  const TaskKind(this.code);

  @override
  final String code;

  static TaskKind fromCode(String code) => _byCode(values, code, (k) => k.code, 'task kind');
}

/// List kind: task list or note list.
enum ListKind implements Coded<String> {
  tasks('TASK'),
  notes('NOTE');

  const ListKind(this.code);

  @override
  final String code;

  static ListKind fromCode(String code) => _byCode(values, code, (k) => k.code, 'list kind');
}

/// What an entry of "Atividades" records.
enum ActivityAction implements Coded<String> {
  created('created'),
  completed('completed'),
  reopened('reopened'),
  wontDo('wont_do'),
  deleted('deleted'),
  restored('restored'),
  title('title'),
  content('content'),
  date('date'),
  priority('priority'),
  moved('moved'),
  repeat('repeat'),
  listCreated('list_created'),
  listTitle('list_title'),
  pinned('pinned'),
  unpinned('unpinned'),
  parent('parent'),
  tags('tags');

  const ActivityAction(this.code);

  @override
  final String code;

  /// Edits of the same field a few minutes apart become one entry (the editor saves as you type).
  bool get merges => this == title || this == content || this == date || this == repeat || this == listTitle || this == tags;

  static ActivityAction fromCode(String code) => _byCode(values, code, (a) => a.code, 'activity action');
}

/// List view mode ("…" menu → View).
enum ViewMode implements Coded<String> {
  list('list'),
  kanban('kanban'),
  timeline('timeline');

  const ViewMode(this.code);

  @override
  final String code;

  static ViewMode fromCode(String code) => _byCode(values, code, (m) => m.code, 'view mode');
}

/// "Group by" from the list header's sort button.
enum Grouping implements Coded<String> {
  custom('sortOrder'),

  /// "Lista": outside a list (smart lists, tags, filters).
  list('project'),
  date('dueDate'),
  modifiedTime('modifiedTime'),
  tag('tag'),
  priority('priority'),
  none('none');

  const Grouping(this.code);

  @override
  final String code;

  static Grouping fromCode(String code) => _byCode(values, code, (g) => g.code, 'group by');
}

/// "Sort by" from the list header's sort button.
enum Sorting implements Coded<String> {
  custom('sortOrder'),
  date('dueDate'),
  modifiedTime('modifiedTime'),
  createdTime('createdTime'),
  title('title'),
  tag('tag'),
  priority('priority');

  const Sorting(this.code);

  @override
  final String code;

  static Sorting fromCode(String code) => _byCode(values, code, (s) => s.code, 'sort by');
}

/// Countdown types.
enum CountdownType implements Coded<String> {
  countdown('countdown'),
  specialDay('specialDay'),
  birthday('birthday'),
  holiday('holiday');

  const CountdownType(this.code);
  @override
  final String code;

  static CountdownType fromCode(String code) => _byCode(values, code, (m) => m.code, 'countdown type');
}

/// "Modo de Cálculo de Dias": the day after the date is day 1 (standard) or the date itself (plusOne).
enum CountMode implements Coded<String> {
  standard('standard'),
  plusOne('plusOne');

  const CountMode(this.code);
  @override
  final String code;

  static CountMode fromCode(String code) => _byCode(values, code, (m) => m.code, 'count mode');
}

/// "Mostrar na Lista Inteligente": when the countdown shows in Hoje / Próximos 7 dias.
enum CountdownVisibility implements Coded<String> {
  onTheDay('onTheDay'),
  threeDaysBefore('threeDays'),
  sevenDaysBefore('sevenDays'),
  always('always'),
  never('never');

  const CountdownVisibility(this.code);
  @override
  final String code;

  static CountdownVisibility fromCode(String code) => _byCode(values, code, (m) => m.code, 'countdown visibility');
}

/// Focus modes: Pomo counts down, Cronômetro counts up.
enum FocusMode implements Coded<String> {
  pomo('pomo'),
  stopwatch('stopwatch');

  const FocusMode(this.code);
  @override
  final String code;

  static FocusMode fromCode(String code) => _byCode(values, code, (m) => m.code, 'focus mode');
}

/// Habit frequency: chosen weekdays, N times a week, or every N days.
enum HabitFrequency implements Coded<String> {
  daily('daily'),
  weekly('weekly'),
  interval('interval');

  const HabitFrequency(this.code);
  @override
  final String code;

  static HabitFrequency fromCode(String code) => _byCode(values, code, (m) => m.code, 'habit frequency');
}

/// "Conquiste tudo" (a simple check-in) or "Atingir uma certa quantia".
enum HabitGoal implements Coded<String> {
  checkIn('checkIn'),
  amount('amount');

  const HabitGoal(this.code);
  @override
  final String code;

  static HabitGoal fromCode(String code) => _byCode(values, code, (m) => m.code, 'habit goal');
}

/// "Ao verificar" of amount goals: add the step (Automático), ask (Manual) or complete at once.
enum HabitCheckMode implements Coded<String> {
  auto('auto'),
  manual('manual'),
  completeAll('completeAll');

  const HabitCheckMode(this.code);
  @override
  final String code;

  static HabitCheckMode fromCode(String code) => _byCode(values, code, (m) => m.code, 'habit check mode');
}

/// A day marked by hand: skipped ("Pular") or failed ("Incompleta", red X).
enum HabitMark implements Coded<String> {
  none('none'),
  skipped('skipped'),
  failed('failed');

  const HabitMark(this.code);
  @override
  final String code;

  static HabitMark fromCode(String code) => _byCode(values, code, (m) => m.code, 'habit mark');
}
