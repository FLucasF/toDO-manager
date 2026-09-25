import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The IANA time-zone database, loaded once ("Fusos adicionais" of the calendar).
/// Notifications load it at start-up; loading it again would not change the local zone, but is slow.
void ensureTimeZones() {
  if (!tz.timeZoneDatabase.isInitialized) tz_data.initializeTimeZones();
}

/// Regions of the zones worth listing (leaves out aliases such as "US/Eastern" and "Etc/GMT+3").
const _regions = {'Africa', 'America', 'Antarctica', 'Asia', 'Atlantic', 'Australia', 'Europe', 'Indian', 'Pacific'};

/// Every city zone id, sorted ("America/Sao_Paulo", ...).
List<String> timeZoneIds() {
  ensureTimeZones();
  return tz.timeZoneDatabase.locations.keys.where((id) => _regions.contains(id.split('/').first)).toList()..sort();
}

/// The zone [id], or null when it is unknown.
tz.Location? findZone(String id) {
  ensureTimeZones();
  return tz.timeZoneDatabase.locations[id];
}

/// What the clock in zone [id] says at the instant [at]; null for an unknown zone.
DateTime? zoneTime(DateTime at, String id) {
  final zone = findZone(id);
  return zone == null ? null : tz.TZDateTime.from(at, zone);
}

/// "Sao Paulo" of "America/Sao_Paulo".
String zoneCity(String id) => id.split('/').last.replaceAll('_', ' ');

/// "GMT-3", "GMT+5:30" of zone [id] at [at].
String zoneOffsetLabel(String id, DateTime at) {
  final zone = findZone(id);
  return zone == null ? id : offsetLabel(tz.TZDateTime.from(at, zone).timeZoneOffset);
}

/// The offset of this device at [at].
String localOffsetLabel(DateTime at) => offsetLabel(at.toLocal().timeZoneOffset);

String offsetLabel(Duration offset) {
  final minutes = offset.inMinutes.abs();
  final sign = offset.isNegative ? '-' : '+';
  final h = minutes ~/ 60, m = minutes % 60;
  if (minutes == 0) return 'GMT';
  return m == 0 ? 'GMT$sign$h' : 'GMT$sign$h:${m.toString().padLeft(2, '0')}';
}

String? _deviceZone;

/// This device's zone id, known once the notifications start (null before that, and in tests).
/// Not `tz.local`: loading the database resets that to UTC.
String? deviceZoneId() => _deviceZone;

void setDeviceZone(String id) => _deviceZone = id;

/// A clock reading [wall] (only its fields count) in zone [id], as an instant on this device.
DateTime wallToLocal(DateTime wall, String id) {
  final zone = findZone(id);
  if (zone == null) return wall;
  // Not TZDateTime.toLocal(): that answers in tz.local, which is UTC until the notifications set it.
  final there = tz.TZDateTime(zone, wall.year, wall.month, wall.day, wall.hour, wall.minute);
  return DateTime.fromMillisecondsSinceEpoch(there.millisecondsSinceEpoch);
}

/// What the clock in zone [id] reads at the instant [at], as a plain local DateTime.
DateTime localToWall(DateTime at, String id) {
  final there = zoneTime(at, id);
  return there == null ? at : DateTime(there.year, there.month, there.day, there.hour, there.minute);
}
