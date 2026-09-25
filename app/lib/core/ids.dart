import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// New UUID v7 identifier: unique and sortable by creation time.
String newId() => _uuid.v7();

/// Fixed id of the Inbox list (the default list; it can't be deleted or archived).
const inboxListId = 'inbox';
