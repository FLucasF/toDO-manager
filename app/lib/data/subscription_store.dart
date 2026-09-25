import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Downloaded `.ics` files of the subscribed calendars, one per calendar, in [dir].
class SubscriptionStore {
  SubscriptionStore(this.dir);

  final Directory dir;

  File _file(String id) => File(p.join(dir.path, '$id.ics'));

  Future<String?> read(String id) async {
    final f = _file(id);
    return f.existsSync() ? f.readAsString() : null;
  }

  Future<void> write(String id, String text) async {
    await dir.create(recursive: true);
    await _file(id).writeAsString(text);
  }

  Future<void> delete(String id) async {
    final f = _file(id);
    if (f.existsSync()) await f.delete();
  }
}

/// Downloads an iCalendar URL (`webcal://` becomes `https://`). Throws [HttpException] or
/// [FormatException] when the answer is not a calendar.
Future<String> downloadCalendar(String url, {Duration timeout = const Duration(seconds: 20)}) async {
  final uri = Uri.parse(url.trim().replaceFirst(RegExp('^webcals?://', caseSensitive: false), 'https://'));
  if (uri.scheme != 'http' && uri.scheme != 'https') throw const FormatException('not an http(s) URL');
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(uri).timeout(timeout);
    final response = await request.close().timeout(timeout);
    if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}', uri: uri);
    final text = await response.transform(const Utf8Decoder(allowMalformed: true)).join().timeout(timeout);
    if (!text.contains('BEGIN:VCALENDAR')) throw const FormatException('not an iCalendar file');
    return text;
  } finally {
    client.close(force: true);
  }
}
