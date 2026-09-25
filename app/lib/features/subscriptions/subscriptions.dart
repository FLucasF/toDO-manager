import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../core/ids.dart';
import '../../data/preferences_repository.dart';
import '../../data/subscription_store.dart';
import '../../domain/import/ical.dart';
import '../../domain/import/imported_task.dart';
import '../../domain/subscriptions.dart';
import '../../l10n/app_localizations.dart';
import '../tasks/list_rows.dart';
import '../common/color_choice.dart';
import '../common/feedback.dart';

/// Where the downloaded calendars are kept (main.dart points it to the app's support folder).
final subscriptionStoreProvider = Provider<SubscriptionStore>((ref) => SubscriptionStore(Directory(Directory.systemTemp.path)));

/// Parsed events of each downloaded URL calendar, by subscription id.
final subscriptionFilesProvider = FutureProvider<Map<String, List<ImportedTask>>>((ref) async {
  // Only a new URL calendar or a new download reads the files again, not every preference change.
  ref.watch(
    preferencesProvider.select(
      (p) => [
        for (final s in p.value?.subscriptions ?? const <CalendarSubscription>[])
          if (s.kind == SubscriptionKind.url) '${s.id}@${s.fetchedAt}',
      ].join(','),
    ),
  );
  final subs = ref.read(preferencesProvider).value?.subscriptions ?? const <CalendarSubscription>[];
  final store = ref.watch(subscriptionStoreProvider);
  final files = <String, List<ImportedTask>>{};
  for (final s in subs.where((s) => s.kind == SubscriptionKind.url)) {
    final text = await store.read(s.id);
    if (text == null) continue;
    try {
      files[s.id] = parseICal(text);
    } on FormatException {
      continue;
    }
  }
  return files;
});

/// Events of the visible subscribed calendars between [from] and [to].
List<SubscribedEvent> subscribedEventsBetween(WidgetRef ref, DateTime from, DateTime to) {
  final subs = (ref.watch(preferencesProvider).value ?? Preferences.defaults).subscriptions;
  final files = ref.watch(subscriptionFilesProvider).value ?? const {};
  return [for (final s in subs) ...subscribedEvents(s, from, to, icsEvents: files[s.id])]..sort((a, b) => a.start.compareTo(b.start));
}

/// The color of a subscribed calendar's events.
Color subscriptionColor(BuildContext context, WidgetRef ref, String calendarId) {
  final subs = (ref.read(preferencesProvider).value ?? Preferences.defaults).subscriptions;
  return parseHexColor(subs.where((s) => s.id == calendarId).firstOrNull?.color) ?? context.tt.palette.green;
}

Future<void> _save(WidgetRef ref, List<CalendarSubscription> subs) => ref.read(preferencesRepositoryProvider).setSubscriptions(subs);

List<CalendarSubscription> _subs(WidgetRef ref) => (ref.read(preferencesProvider).value ?? Preferences.defaults).subscriptions;

/// Downloads a URL calendar again ("Atualizar"). Returns false when it failed.
Future<bool> refreshSubscription(WidgetRef ref, CalendarSubscription sub) async {
  final url = sub.url;
  if (sub.kind != SubscriptionKind.url || url == null) return true;
  try {
    final text = await downloadCalendar(url);
    await ref.read(subscriptionStoreProvider).write(sub.id, text);
    await _save(ref, [for (final s in _subs(ref)) s.id == sub.id ? s.copyWith(fetchedAt: DateTime.now()) : s]);
    ref.invalidate(subscriptionFilesProvider);
    return true;
  } on Object {
    return false;
  }
}

/// Downloads the URL calendars not updated in the last 12 hours (on start).
Future<void> refreshStaleSubscriptions(WidgetRef ref) async {
  final now = DateTime.now();
  for (final s in _subs(ref)) {
    if (s.kind == SubscriptionKind.url && (s.fetchedAt == null || now.difference(s.fetchedAt!) > const Duration(hours: 12))) {
      await refreshSubscription(ref, s);
    }
  }
}

Future<void> removeSubscription(WidgetRef ref, CalendarSubscription sub) async {
  await _save(ref, [
    for (final s in _subs(ref))
      if (s.id != sub.id) s,
  ]);
  await ref.read(subscriptionStoreProvider).delete(sub.id);
  ref.invalidate(subscriptionFilesProvider);
}

Future<void> setSubscriptionVisible(WidgetRef ref, CalendarSubscription sub, {required bool visible}) =>
    _save(ref, [for (final s in _subs(ref)) s.id == sub.id ? s.copyWith(visible: visible) : s]);

/// "Feriados": Brazil's holidays, worked out on the device.
Future<void> addHolidays(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context);
  if (_subs(ref).any((s) => s.kind == SubscriptionKind.holidays)) return;
  await _save(ref, [
    ..._subs(ref),
    CalendarSubscription(id: newId(), name: t.subscriptionHolidaysName, kind: SubscriptionKind.holidays, color: '#35D870'),
  ]);
}

/// "URL": name and address of an `.ics` calendar; it is downloaded right away.
Future<void> addUrlSubscription(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context);
  final name = TextEditingController(), url = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.subscriptionAddUrl, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: url,
              autofocus: true,
              decoration: InputDecoration(labelText: t.subscriptionUrl, hintText: 'https://…/calendario.ics'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: t.subscriptionName),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.actionCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.subscriptionSubscribe)),
      ],
    ),
  );
  final address = url.text.trim(), title = name.text.trim();
  name.dispose();
  url.dispose();
  if (ok != true || address.isEmpty || !context.mounted) return;
  final sub = CalendarSubscription(
    id: newId(),
    name: title.isEmpty ? Uri.tryParse(address)?.host ?? address : title,
    kind: SubscriptionKind.url,
    url: address,
    color: '#4CA1FF',
  );
  await _save(ref, [..._subs(ref), sub]);
  final fetched = await refreshSubscription(ref, sub);
  if (!context.mounted) return;
  showToast(context, fetched ? t.subscriptionAdded : t.subscriptionFailed);
}

/// An event of a subscribed calendar: read only, so a click just shows it.
Future<void> showSubscribedEvent(
  BuildContext context,
  WidgetRef ref,
  String title,
  DateTime start,
  DateTime end, {
  required bool isAllDay,
  required String calendarId,
  String description = '',
}) {
  final t = AppLocalizations.of(context);
  final tt = context.tt;
  final dates = DateLabels(t);
  final today = startOfDay(DateTime.now());
  final calendar = (ref.read(preferencesProvider).value ?? Preferences.defaults).subscriptions.where((s) => s.id == calendarId).firstOrNull;
  final when = startOfDay(start) == startOfDay(end) || !end.isAfter(start)
      ? dates.detailDate(start, isAllDay: isAllDay, today: today)
      : dates.detailRange(start, end, isAllDay: isAllDay, today: today);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(when, style: TextStyle(color: tt.textSecondary)),
          if (calendar != null) ...[
            const SizedBox(height: 6),
            Text(
              calendar.name,
              style: TextStyle(fontSize: TtText.small, color: subscriptionColor(context, ref, calendarId)),
            ),
          ],
          if (description.isNotEmpty) ...[const SizedBox(height: 12), Text(description, style: TextStyle(color: tt.text))],
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionClose))],
    ),
  );
}

/// "Calendários assinados" in Hoje and Próximos 7 dias: the events of those days.
class SubscribedEventsSection extends ConsumerWidget {
  const SubscribedEventsSection({super.key, required this.events, required this.today});

  final List<SubscribedEvent> events;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListSectionTitle(t.subscriptionsTitle),
        for (final e in events)
          ListItemRow(
            onTap: () => unawaited(
              showSubscribedEvent(context, ref, e.title, e.start, e.end, isAllDay: e.isAllDay, calendarId: e.calendarId, description: e.description),
            ),
            leading: Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(color: subscriptionColor(context, ref, e.calendarId), borderRadius: BorderRadius.circular(2)),
            ),
            title: e.title,
            trailing: Text(
              dates.rowDate(e.start, isAllDay: e.isAllDay, today: today),
              style: TextStyle(fontSize: TtText.small, color: tt.primary),
            ),
          ),
      ],
    );
  }
}

/// Settings → Integrações e Importação → "Calendários assinados".
class SubscriptionsSettings extends ConsumerWidget {
  const SubscriptionsSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final subs = (ref.watch(preferencesProvider).value ?? Preferences.defaults).subscriptions;
    final today = startOfDay(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in subs)
          ListTile(
            leading: Icon(s.kind == SubscriptionKind.holidays ? Icons.celebration_outlined : Icons.link, color: parseHexColor(s.color) ?? tt.primary),
            title: Text(s.name),
            subtitle: Text(
              s.kind == SubscriptionKind.holidays
                  ? t.subscriptionHolidaysHint
                  : '${s.url}\n${s.fetchedAt == null ? t.subscriptionNeverFetched : t.subscriptionFetched(DateLabels(t).detailDate(s.fetchedAt!, isAllDay: false, today: today))}',
              style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
            ),
            isThreeLine: s.kind == SubscriptionKind.url,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: s.visible,
                  onChanged: (v) => unawaited(setSubscriptionVisible(ref, s, visible: v)),
                ),
                if (s.kind == SubscriptionKind.url)
                  IconButton(
                    tooltip: t.subscriptionRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: () async {
                      final ok = await refreshSubscription(ref, s);
                      if (context.mounted) showToast(context, ok ? t.subscriptionUpdated : t.subscriptionFailed);
                    },
                  ),
                IconButton(
                  tooltip: t.actionDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => unawaited(removeSubscription(ref, s)),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            if (!subs.any((s) => s.kind == SubscriptionKind.holidays))
              TextButton.icon(
                icon: const Icon(Icons.celebration_outlined, size: 18),
                label: Text(t.subscriptionAddHolidays),
                onPressed: () => unawaited(addHolidays(context, ref)),
              ),
            TextButton.icon(
              icon: const Icon(Icons.add_link, size: 18),
              label: Text(t.subscriptionAddUrl),
              onPressed: () => unawaited(addUrlSubscription(context, ref)),
            ),
          ],
        ),
      ],
    );
  }
}
