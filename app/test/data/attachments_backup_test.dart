import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/attachment_store.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/views.dart';
import 'package:task_manager/features/backup/backup_service.dart';

void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('tarefas_test_'));
  tearDown(() => temp.deleteSync(recursive: true));

  test('the store copies files, refuses escaping references and formats sizes', () async {
    final source = File(p.join(temp.path, 'nota fiscal.pdf'))..writeAsBytesSync(List.filled(2048, 1));
    final store = AttachmentStore(Directory(p.join(temp.path, 'store')));
    final reference = await store.add(source);
    expect(reference, endsWith('/nota fiscal.pdf'));
    expect(store.fileOf(reference)!.lengthSync(), 2048);
    expect(store.describeSize(reference), '2,0 KB');
    expect(store.fileOf('../x/y'), isNull);
    expect(store.fileOf('a/../../b'), isNull);
    expect(AttachmentStore.formatSize(86), '86 B');
    expect(store.all().single.$1, reference);
  });

  test('a backup carries the rows and the attachments; import replaces both', () async {
    final clock = FixedClock(DateTime(2026, 9, 25));
    final source = AppDatabase(NativeDatabase.memory());
    final storeA = AttachmentStore(Directory(p.join(temp.path, 'a')));
    final file = File(p.join(temp.path, 'foto.png'))..writeAsBytesSync([1, 2, 3]);
    final reference = await storeA.add(file);
    final repo = Repository(source, clock: clock);
    final id = await repo.createTask(listId: inboxListId, title: 'Com anexo', content: '![file]($reference)');
    await repo.addComment(id, 'Comentário');
    final picturesA = Directory(p.join(temp.path, 'pics_a'))..createSync();
    File(p.join(picturesA.path, 'foto.png')).writeAsBytesSync([1, 2, 3]);
    final bytes = await BackupService(source, tempDir: temp, attachments: storeA, folders: {'countdown_images/': picturesA}).export();
    await source.close();

    final target = AppDatabase(NativeDatabase.memory());
    final storeB = AttachmentStore(Directory(p.join(temp.path, 'b')));
    File(p.join(storeB.root.path, 'old', 'velho.txt'))
      ..createSync(recursive: true)
      ..writeAsStringSync('x');
    final picturesB = Directory(p.join(temp.path, 'pics_b'))..createSync();
    File(p.join(picturesB.path, 'antiga.png')).writeAsBytesSync([9]);
    await BackupService(target, tempDir: temp, attachments: storeB, folders: {'countdown_images/': picturesB}).import(bytes);
    // Other folders (countdown pictures) come back too, replacing what was there.
    expect(picturesB.listSync().map((f) => p.basename(f.path)), ['foto.png']);
    expect(File(p.join(picturesB.path, 'foto.png')).readAsBytesSync(), [1, 2, 3]);

    final s = await Repository(target, clock: clock).loadSnapshot();
    expect(s.taskById[id]!.title, 'Com anexo');
    expect((await Repository(target).watchComments(id).first).single.body, 'Comentário');
    expect(storeB.fileOf(reference)!.readAsBytesSync(), [1, 2, 3]);
    expect(storeB.all().map((e) => e.$1), [reference], reason: 'the old files are gone');
    // The row shows the paperclip.
    final row = buildView(s, const ListScope(inboxListId), DateTime(2026, 9, 25)).groups.expand((g) => g.rows).single;
    expect(row.hasAttachment, isTrue);
    await target.close();
  });

  test('a backup without files (the automatic ones) restores the rows and keeps the current files', () async {
    final clock = FixedClock(DateTime(2026, 9, 25));
    final source = AppDatabase(NativeDatabase.memory());
    final storeA = AttachmentStore(Directory(p.join(temp.path, 'a')));
    await storeA.add(File(p.join(temp.path, 'foto.png'))..writeAsBytesSync([1, 2, 3]));
    final id = await Repository(source, clock: clock).createTask(listId: inboxListId, title: 'Só dados');
    final bytes = await BackupService(source, tempDir: temp, attachments: storeA).export(withFiles: false);
    await source.close();

    final target = AppDatabase(NativeDatabase.memory());
    final storeB = AttachmentStore(Directory(p.join(temp.path, 'b')));
    final kept = await storeB.add(File(p.join(temp.path, 'meu.txt'))..writeAsStringSync('x'));
    await BackupService(target, tempDir: temp, attachments: storeB).import(bytes);
    expect((await Repository(target, clock: clock).loadSnapshot()).taskById[id]!.title, 'Só dados');
    expect(storeB.all().map((e) => e.$1), [kept]);
    await target.close();
  });
}
