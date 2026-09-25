import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/format/date_labels.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/data/url_title.dart';
import 'package:task_manager/domain/task_defaults.dart';

void main() {
  test('"Análise de URL": only a bare http(s) link counts; the page title is read from <title>', () {
    expect(bareUrl(' https://flutter.dev/docs '), 'https://flutter.dev/docs');
    expect(bareUrl('ler https://flutter.dev'), isNull);
    expect(bareUrl('ftp://x.com'), isNull);
    expect(bareUrl('Comprar pão'), isNull);
    expect(pageTitle('<html><head><TITLE>\n  Flutter &amp; Dart  </TITLE></head></html>'), 'Flutter & Dart');
    expect(pageTitle('<html></html>'), isNull);
  });

  test('the page title replaces the link, which moves to the content, unless the title changed', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = Repository(db, clock: FixedClock(DateTime(2026, 9, 25)));
    final id = await repo.createTask(listId: inboxListId, title: 'https://flutter.dev');
    await repo.titleFromLink(id, title: 'Flutter', url: 'https://flutter.dev');
    final t = await repo.task(id);
    expect((t.title, t.content), ('Flutter', 'https://flutter.dev'));
    await repo.titleFromLink(id, title: 'Outro', url: 'https://flutter.dev');
    expect((await repo.task(id)).title, 'Flutter', reason: 'the title is no longer the link');
  });

  test('"Formato de data" and the default tag survive', () {
    addTearDown(() => DateConventions.dateOrder = DateOrder.dayMonthYear);
    final d = DateTime(2026, 12, 31);
    expect(DateLabels.numeric(d), '31/12/2026');
    DateConventions.dateOrder = DateOrder.monthDayYear;
    expect((DateLabels.numeric(d), DateLabels.numeric(d, withYear: false)), ('12/31/2026', '12/31'));
    DateConventions.dateOrder = DateOrder.yearMonthDay;
    expect(DateLabels.numeric(d), '2026/12/31');

    final back = TaskDefaults.fromJson(const TaskDefaults(tagId: 'tag-1', parseUrls: true).toJson());
    expect((back.tagId, back.parseUrls), ('tag-1', true));
    expect(const TaskDefaults().parseUrls, isFalse, reason: 'off by default: it reads the page on the internet');
  });
}
