import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/quick_add.dart';

void main() {
  // Thursday, 2026-09-24 at 21:00.
  final now = DateTime(2026, 9, 24, 21);
  QuickAdd parse(String s, {List<String> lists = const []}) => parseQuickAdd(s, now: now, listNames: lists);

  test('priority, tag and list tokens are recognized and removed', () {
    final r = parse('Reunião !Alta #clone ~Trabalho', lists: ['Trabalho', 'Casa']);
    expect(r.title, 'Reunião');
    expect(r.priority, Priority.high);
    expect(r.tagNames, ['clone']);
    expect(r.listName, 'Trabalho');
  });

  test('accents and case do not matter for priority', () {
    expect(parse('x !média').priority, Priority.medium);
    expect(parse('x !MEDIA').priority, Priority.medium);
    expect(parse('x !baixa').priority, Priority.low);
  });

  test('an unknown !word stays in the title', () {
    expect(parse('Comprar !urgente').title, 'Comprar !urgente');
  });

  test('multi-word list names with ~', () {
    expect(parse('Tarefa ~Caixa de Entrada', lists: ['Caixa de Entrada']).listName, 'Caixa de Entrada');
  });

  test('relative days in PT-BR and English', () {
    expect(parse('Pagar conta amanhã').dueDate, DateTime(2026, 9, 25));
    expect(parse('Pagar conta amanha').title, 'Pagar conta');
    expect(parse('Ligar hoje').dueDate, DateTime(2026, 9, 24));
    expect(parse('Call mom tomorrow').dueDate, DateTime(2026, 9, 25));
    expect(parse('Viagem depois de amanhã').dueDate, DateTime(2026, 9, 26));
    expect(parse('Revisar em 3 dias').dueDate, DateTime(2026, 9, 27));
  });

  test('weekday names point to the next such day', () {
    expect(parse('Feira sábado').dueDate, DateTime(2026, 9, 26));
    expect(parse('Reunião quinta').dueDate, DateTime(2026, 10, 1));
    expect(parse('Gym monday').dueDate, DateTime(2026, 9, 28));
  });

  test('numeric dates roll to next year when already past', () {
    expect(parse('Entrega 30/09').dueDate, DateTime(2026, 9, 30));
    expect(parse('Aniversário 10/01').dueDate, DateTime(2027, 1, 10));
    expect(parse('Prova 5/10/2026').dueDate, DateTime(2026, 10, 5));
  });

  test('times: "amanhã às 15h", "tomorrow 3pm", "15:30"', () {
    final a = parse('Dentista amanhã às 15h');
    expect(a.title, 'Dentista');
    expect(a.dueDate, DateTime(2026, 9, 25, 15));
    expect(a.isAllDay, isFalse);
    expect(parse('Call tomorrow 3pm').dueDate, DateTime(2026, 9, 25, 15));
    expect(parse('Reunião sexta 9:30').dueDate, DateTime(2026, 9, 25, 9, 30));
  });

  test('a time already past today with no day means tomorrow', () {
    expect(parse('Correr às 7h').dueDate, DateTime(2026, 9, 25, 7));
    expect(parse('Jantar 22h').dueDate, DateTime(2026, 9, 24, 22));
  });

  test('date recognition can be turned off', () {
    final r = parseQuickAdd('Ler amanhã', now: now, recognizeDates: false);
    expect(r.dueDate, isNull);
    expect(r.title, 'Ler amanhã');
  });

  test('parseTime accepts the usual ways of typing a time', () {
    const cases = {
      '14:30': (14, 30),
      '14h30': (14, 30),
      '14h': (14, 0),
      '2pm': (14, 0),
      '1430': (14, 30),
      '930': (9, 30),
      '9': (9, 0),
      'às 8h': (8, 0),
    };
    for (final c in cases.entries) {
      final t = parseTime(c.key);
      expect((t?.hour, t?.minute), c.value, reason: c.key);
    }
    for (final bad in ['', '25:00', '14:75', 'amanhã', '12 horas e meia']) {
      expect(parseTime(bad), isNull, reason: bad);
    }
  });

  test('activeToken finds the token being typed', () {
    expect(activeToken('Comprar pão #mer', 16)?.query, 'mer');
    expect(activeToken('Comprar pão #mer', 16)?.trigger, '#');
    expect(activeToken('!al', 3)?.start, 0);
    expect(activeToken('Comprar pão', 11), isNull);
    expect(activeToken('email a@b', 9), isNull, reason: 'the trigger must start a word');
    expect(activeToken('Ler ~', 5)?.query, '');
  });

  test('replaceToken swaps the token and keeps the rest', () {
    const text = 'Ler #li amanhã';
    final r = replaceToken(text, activeToken(text, 7)!, '#livros ');
    expect(r.text, 'Ler #livros amanhã');
    expect(r.cursor, 12);
    final end = replaceToken('Ler !al', activeToken('Ler !al', 7)!, '!alta ');
    expect(end.text, 'Ler !alta ');
  });

  test('settings can keep the recognized date and #tag in the title', () {
    final kept = parseQuickAdd('Dentista amanhã 15h #saúde', now: now, removeDateText: false, removeTagText: false);
    expect((kept.title, kept.dueDate), ('Dentista amanhã 15h #saúde', DateTime(2026, 9, 25, 15)));
    expect(kept.tagNames, ['saúde']);
    final off = parseQuickAdd('Dentista amanhã', now: now, recognizeDates: false);
    expect((off.title, off.dueDate), ('Dentista amanhã', null));
  });
}
