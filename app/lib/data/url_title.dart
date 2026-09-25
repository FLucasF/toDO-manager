import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// The link when [title] is nothing but an http(s) URL ("Análise de URL").
String? bareUrl(String title) {
  final text = title.trim();
  final uri = Uri.tryParse(text);
  if (text.contains(' ') || uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) return null;
  return text;
}

/// The `<title>` of the page at [url], or null (no network, not HTML, no title, too slow).
Future<String?> fetchPageTitle(String url, {Duration timeout = const Duration(seconds: 8)}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(Uri.parse(url)).timeout(timeout);
    final response = await request.close().timeout(timeout);
    if (response.statusCode >= 400) return null;
    // The title is near the top: read at most 256 KB.
    final bytes = <int>[];
    await for (final chunk in response.timeout(timeout)) {
      bytes.addAll(chunk);
      if (bytes.length > 256 * 1024) break;
    }
    return pageTitle(utf8.decode(bytes, allowMalformed: true));
  } on Object catch (e) {
    debugPrint('Page title not read: $e');
    return null;
  } finally {
    client.close(force: true);
  }
}

/// The text of the first `<title>` of [html], with the common entities decoded.
String? pageTitle(String html) {
  final match = RegExp(r'<title[^>]*>([\s\S]*?)</title>', caseSensitive: false).firstMatch(html);
  final raw = match?.group(1)?.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (raw == null || raw.isEmpty) return null;
  return raw
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ');
}
