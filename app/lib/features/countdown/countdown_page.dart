import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/format/date_labels.dart';
import '../../domain/countdown.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/preferences_repository.dart';
import '../../data/repository.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/feedback.dart';
import '../shell/app_shell.dart';
import 'countdown_card.dart';
import 'countdown_form.dart';

/// The countdowns of a new TickTick account, created once on the first run: "Use o
/// Tarefas" (since today), "Fim de semana" (every Saturday) and "Dia de Ano Novo".
Future<void> seedBuiltInCountdowns(Repository repo, PreferencesRepository prefs, AppLocalizations t, DateTime now) async {
  if (await prefs.builtInCountdownsSeeded()) return;
  final today = startOfDay(now);
  await repo.createCountdown(name: t.countdownSeedUseApp, date: today, countMode: CountMode.plusOne);
  final saturday = today.add(Duration(days: (DateTime.saturday - today.weekday) % 7));
  await repo.createCountdown(name: t.countdownSeedWeekend, date: saturday, repeatRule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=SA');
  await repo.createCountdown(
    name: t.countdownSeedNewYear,
    date: DateTime(today.year + 1),
    type: CountdownType.holiday,
    repeatRule: 'FREQ=YEARLY;INTERVAL=1;BYMONTH=1;BYMONTHDAY=1',
  );
  await prefs.markBuiltInCountdownsSeeded();
}

/// Countdown module (`#countdown`).
class CountdownPage extends ConsumerStatefulWidget {
  const CountdownPage({super.key});

  @override
  ConsumerState<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends ConsumerState<CountdownPage> {
  bool _archived = false;
  bool _grouped = false;

  /// Selected group tab while grouped; null means "Todas".
  CountdownType? _tab;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final countdowns = sortCountdowns(
      s.countdowns.where((c) => (c.archivedAt != null) == _archived && (!_grouped || _tab == null || c.type == _tab)),
      now,
    );

    // A fixed card height: on a phone the two columns are narrow, and a width-based height cut the
    // legend off.
    Widget grid(List<Countdown> items) => GridView(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 170,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [for (final c in items) _CountdownTile(countdown: c)],
    );

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 16, 10),
      child: Row(
        children: [
          const DrawerMenuButton(),
          PopupMenuButton<bool>(
            tooltip: '',
            onSelected: (archived) => setState(() => _archived = archived),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: false, checked: !_archived, child: Text(t.countdownActive)),
              CheckedPopupMenuItem(value: true, checked: _archived, child: Text(t.countdownArchived)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                    _archived ? t.countdownArchivedTitle : t.navCountdown,
                    style: TextStyle(fontSize: TtText.listTitle, fontWeight: FontWeight.w600, color: tt.text),
                  ),
                  Icon(Icons.expand_more, size: 18, color: tt.textTertiary),
                ],
              ),
            ),
          ),
          const Spacer(),
          PopupMenuButton<CountdownType>(
            tooltip: '',
            icon: Icon(Icons.add, color: tt.textSecondary),
            onSelected: (type) => unawaited(showCountdownForm(context, type: type)),
            itemBuilder: (_) => [
              for (final type in CountdownType.values) PopupMenuItem(value: type, height: 36, child: Text(countdownTypeLabel(t, type))),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: '',
            icon: Icon(Icons.more_horiz, color: tt.textSecondary),
            // "Mostrar Grupo" turns into "Ocultar Grupo" once the tabs are shown.
            onSelected: (_) => setState(() {
              _grouped = !_grouped;
              _tab = null;
            }),
            itemBuilder: (_) => [PopupMenuItem(value: 'group', height: 36, child: Text(_grouped ? t.countdownHideGroup : t.countdownShowGroup))],
          ),
        ],
      ),
    );

    final body = countdowns.isEmpty
        ? Center(
            child: Text(t.countdownEmpty, style: TextStyle(color: tt.textTertiary)),
          )
        : ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [grid(countdowns)]);

    final page = Container(
      color: tt.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (_grouped) _GroupTabs(selected: _tab, onSelected: (type) => setState(() => _tab = type)),
          Expanded(child: body),
        ],
      ),
    );
    return ModuleScaffold(module: AppModule.countdown, child: page);
  }
}

class _CountdownTile extends ConsumerWidget {
  const _CountdownTile({required this.countdown});

  final Countdown countdown;

  Future<void> _menu(BuildContext context, WidgetRef ref, Offset at) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(repositoryProvider);
    final c = countdown;
    final archived = c.archivedAt != null;
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        if (archived)
          PopupMenuItem(value: 'restore', height: 36, child: Text(t.countdownRestore))
        else ...[
          PopupMenuItem(value: 'edit', height: 36, child: Text(t.countdownEdit)),
          PopupMenuItem(value: 'style', height: 36, child: Text(t.countdownStyle)),
          PopupMenuItem(value: 'notes', height: 36, child: Text(t.countdownNotes)),
          PopupMenuItem(value: 'pin', height: 36, child: Text(c.pinnedAt == null ? t.countdownPin : t.countdownUnpin)),
          PopupMenuItem(value: 'archive', height: 36, child: Text(t.countdownArchive)),
        ],
        PopupMenuItem(value: 'delete', height: 36, child: Text(t.countdownDelete)),
      ],
    );
    if (!context.mounted || picked == null) return;
    switch (picked) {
      case 'edit':
        await showCountdownForm(context, type: c.type, editing: c);
      case 'style':
        await _pickStyle(context, ref);
      case 'notes':
        await _editNotes(context, ref);
      case 'pin':
        await repo.pinCountdown(c.id, pinned: c.pinnedAt == null);
      case 'archive':
        await repo.archiveCountdown(c.id, archived: true);
        if (context.mounted) showToast(context, t.toastArchived);
      case 'restore':
        await repo.archiveCountdown(c.id, archived: false);
      case 'delete':
        await repo.deleteCountdown(c.id);
    }
  }

  Future<void> _pickStyle(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    var style = countdown.style;
    var color = countdown.color;
    var icon = countdown.icon;
    var iconColor = countdown.iconColor;
    var image = countdown.image;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final tt = context.tt;
          return AlertDialog(
            title: Text(t.countdownStyle, style: const TextStyle(fontSize: 15)),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < countdownStyles; i++)
                        GestureDetector(
                          onTap: () => setState(() => style = i),
                          child: Container(
                            width: 128,
                            height: 84,
                            decoration: BoxDecoration(
                              border: Border.all(color: style == i ? tt.primary : Colors.transparent, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CountdownCardBody(
                              countdown: countdown.copyWith(icon: Value(icon), iconColor: Value(iconColor), image: Value(image)),
                              style: i,
                              color: parseHexColor(color) ?? tt.primary,
                              compact: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CountdownLookFields(
                    icon: icon,
                    iconColor: iconColor,
                    image: image,
                    onIcon: (v, c) => setState(() {
                      icon = v;
                      iconColor = c;
                    }),
                    onImage: (v) => setState(() => image = v),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in presetColors)
                        GestureDetector(
                          onTap: () => setState(() => color = c),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: parseHexColor(c),
                              shape: BoxShape.circle,
                              border: Border.all(color: color == c ? tt.text : Colors.transparent, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.actionCancel)),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.actionOk)),
            ],
          );
        },
      ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).setCountdownStyle(countdown.id, style: style, color: color, icon: icon, iconColor: iconColor, image: image);
    }
  }

  Future<void> _editNotes(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController(text: countdown.note);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.countdownNotes, style: const TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 8,
            minLines: 4,
            decoration: InputDecoration(hintText: t.countdownNoteHint),
          ),
        ),
        actions: [
          // Inserts the date and time where the cursor is.
          IconButton(
            tooltip: t.formatTime,
            icon: const Icon(Icons.schedule, size: 18),
            onPressed: () {
              final now = ref.read(clockProvider).now();
              final stamp = '${DateLabels.numeric(now)} ${DateLabels.time(now)}';
              final at = controller.selection.isValid ? controller.selection.start : controller.text.length;
              final end = controller.selection.isValid ? controller.selection.end : at;
              controller.value = TextEditingValue(
                text: controller.text.replaceRange(at, end, stamp),
                selection: TextSelection.collapsed(offset: at + stamp.length),
              );
            },
          ),
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.actionClose)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.actionSave)),
        ],
      ),
    );
    final text = controller.text;
    controller.dispose();
    if (ok == true) await ref.read(repositoryProvider).setCountdownNote(countdown.id, text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = context.tt;
    return GestureDetector(
      onTap: countdown.archivedAt == null ? () => unawaited(showCountdownForm(context, type: countdown.type, editing: countdown)) : null,
      onSecondaryTapUp: (d) => unawaited(_menu(context, ref, d.globalPosition)),
      onLongPressStart: (d) => unawaited(_menu(context, ref, d.globalPosition)),
      child: Opacity(
        opacity: countdown.archivedAt == null ? 1 : 0.6,
        child: CountdownCardBody(countdown: countdown, style: countdown.style, color: parseHexColor(countdown.color) ?? tt.primary),
      ),
    );
  }
}

/// Group tabs shown by "Mostrar Grupo": Todas · Contagem Regressiva · Data Especial · Aniversário · Feriado.
class _GroupTabs extends StatelessWidget {
  const _GroupTabs({required this.selected, required this.onSelected});

  final CountdownType? selected;
  final ValueChanged<CountdownType?> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    Widget tab(CountdownType? type, String label) {
      final active = type == selected;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: active,
          showCheckmark: false,
          selectedColor: tt.primary,
          labelStyle: TextStyle(fontSize: 13, color: active ? Colors.white : tt.textSecondary),
          onSelected: (_) => onSelected(type),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(children: [tab(null, t.countdownAll), for (final type in CountdownType.values) tab(type, countdownTypeLabel(t, type))]),
    );
  }
}
