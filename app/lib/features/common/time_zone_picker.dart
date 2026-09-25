import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/time_zones.dart';
import '../../l10n/app_localizations.dart';

/// Picks a time zone by city or id; null when cancelled.
Future<String?> pickTimeZone(BuildContext context, DateTime now) => showDialog<String>(
  context: context,
  builder: (_) => _TimeZonePicker(now: now),
);

class _TimeZonePicker extends StatefulWidget {
  const _TimeZonePicker({required this.now});

  final DateTime now;

  @override
  State<_TimeZonePicker> createState() => _TimeZonePickerState();
}

class _TimeZonePickerState extends State<_TimeZonePicker> {
  final _all = timeZoneIds();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final q = _query.trim().toLowerCase().replaceAll(' ', '_');
    final shown = q.isEmpty ? _all : _all.where((id) => id.toLowerCase().contains(q)).toList();
    return AlertDialog(
      title: Text(t.calendarAddTimeZone, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 360,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(hintText: t.calendarSearchTimeZone, prefixIcon: const Icon(Icons.search, size: 18), isDense: true),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (context, i) => ListTile(
                  dense: true,
                  title: Text(zoneCity(shown[i]), style: TextStyle(color: tt.text)),
                  subtitle: Text(shown[i], style: TextStyle(fontSize: 11, color: tt.textTertiary)),
                  trailing: Text(zoneOffsetLabel(shown[i], widget.now), style: TextStyle(color: tt.textSecondary)),
                  onTap: () => Navigator.pop(context, shown[i]),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel))],
    );
  }
}
