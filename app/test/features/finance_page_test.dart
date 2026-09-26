import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';

void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 9, 24, 12));

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester, [int steps = 8]) async {
    for (var i = 0; i < steps; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpApp(WidgetTester tester, String location, {Size size = const Size(1600, 1000)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
        child: TasksApp(initialLocation: location),
      ),
    );
    await settle(tester, 10);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  }

  Future<void> pick(WidgetTester tester, String field, String option) async {
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String?>, field));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Finanças: the icon bar opens it; default categories; a new expense shows in the month', (tester) async {
    await pumpApp(tester, '/q/all/tasks');
    await tester.tap(find.byTooltip('Finanças'));
    await settle(tester);
    expect(find.text('Lançamentos'), findsOneWidget);
    expect(find.text('Nenhum lançamento neste período.'), findsOneWidget);
    expect(find.text('Setembro 2026'), findsOneWidget);

    await tester.tap(find.byTooltip('Novo lançamento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '1.234,5');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Feira do mês');
    await pick(tester, 'Categoria', '🛒 Mercado');
    await tester.tap(find.text('Salvar'));
    await settle(tester);

    expect(find.text('Feira do mês'), findsOneWidget);
    // The row, the Saldo and the day's total; Despesas without the sign.
    expect(find.text(r'-R$ 1.234,50'), findsNWidgets(3));
    expect(find.text(r'R$ 1.234,50'), findsOneWidget);
    expect(find.text('Quinta-feira, Hoje'), findsOneWidget);

    // Categorias: this month's total beside the category.
    await tester.tap(find.text('Categorias'));
    await settle(tester);
    expect(find.text(r'R$ 1.234,50 neste mês'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('a limit warns from 80%; income is green; filters and delete with undo', (tester) async {
    final repo = FinanceRepository(db, clock: clock);
    late String market;
    await tester.runAsync(() async {
      market = await repo.createCategory(name: 'Mercado', kind: FinKind.expense, icon: '🛒', monthlyLimit: 10000);
      await repo.createCategory(name: 'Salário', kind: FinKind.income, icon: '💰');
      await repo.addEntry(kind: FinKind.expense, amount: 7000, date: DateTime(2026, 9, 10), description: 'Pão', categoryId: market);
    });
    await pumpApp(tester, '/finance/categories');
    expect(find.text(r'R$ 70,00 de R$ 100,00'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Lançamentos'));
    await settle(tester);
    await tester.tap(find.byTooltip('Novo lançamento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '15');
    await pick(tester, 'Categoria', '🛒 Mercado');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text(r'Mercado: 85% do limite do mês (R$ 85,00 de R$ 100,00).'), findsOneWidget);

    // Income: its own categories, and a "+".
    await tester.tap(find.byTooltip('Novo lançamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '3000');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Pagamento');
    await pick(tester, 'Categoria', '💰 Salário');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text(r'+R$ 3.000,00'), findsOneWidget);
    expect(find.text(r'R$ 2.915,00'), findsOneWidget);

    // Filter: only income.
    Finder kindItem(String label) => find.widgetWithText(CheckedPopupMenuItem<int>, label);
    await tester.tap(find.text('Receitas e despesas'));
    await tester.pumpAndSettle();
    await tester.tap(kindItem('Receitas'));
    await settle(tester);
    expect(find.text('Pagamento'), findsOneWidget);
    expect(find.text('Pão'), findsNothing);
    // The chip now says "Receitas" (after the summary's label).
    await tester.tap(find.text('Receitas').last);
    await tester.pumpAndSettle();
    await tester.tap(kindItem('Receitas e despesas'));
    await settle(tester);

    // Delete, then undo.
    await tester.longPress(find.text('Pão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deletar'));
    await settle(tester);
    expect(find.text('Pão'), findsNothing);
    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    expect(find.text('Pão'), findsOneWidget);

    // The month before is empty.
    await tester.tap(find.byIcon(Icons.chevron_left));
    await settle(tester);
    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.text('Nenhum lançamento neste período.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  Future<void> pickNumber(WidgetTester tester, String field, String option) async {
    await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, field));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Cartões: a new card, a purchase in 3 installments goes to its invoices, paying the invoice', (tester) async {
    await pumpApp(tester, '/finance/cards');
    expect(find.textContaining('Nenhum cartão ainda'), findsOneWidget);
    await tester.tap(find.text('Novo cartão'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nome do cartão'), 'Nubank');
    await pickNumber(tester, 'Dia do fechamento', '5');
    await pickNumber(tester, 'Dia do vencimento', '12');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('Fecha dia 5 · vence dia 12'), findsOneWidget);
    // The 24th is after the closing: October's invoice, still open.
    expect(find.text('Fatura de Outubro 2026'), findsOneWidget);
    expect(find.text('Sem compras'), findsOneWidget);

    await tester.tap(find.byTooltip('Novo lançamento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '300');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Fone');
    await pick(tester, 'Cartão', 'Nubank');
    await pickNumber(tester, 'Parcelas', r'3x de R$ 100,00');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('Aberta'), findsOneWidget);
    expect(find.textContaining('1/3'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await settle(tester);
    expect(find.text('Fatura de Novembro 2026'), findsOneWidget);
    expect(find.textContaining('2/3'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await settle(tester);

    await tester.tap(find.text('Pagar fatura'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Valor pago'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('Pagar fatura'), findsNothing);
    expect(find.text('Pagamentos'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Contas fixas: a monthly bill due on the 20th is late; paying it makes the entry', (tester) async {
    await pumpApp(tester, '/finance/recurring');
    expect(find.textContaining('Nenhuma conta fixa ainda'), findsOneWidget);
    await tester.tap(find.text('Nova conta fixa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Aluguel');
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '1500');
    // The menu opens around today (the 24th).
    await pickNumber(tester, 'Dia do vencimento', '20');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('Vencimentos do mês'), findsOneWidget);
    expect(find.text('Contas cadastradas'), findsOneWidget);
    expect(find.text('vence 20/09'), findsOneWidget);
    expect(find.text('Todo dia 20'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Pagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('pago em 24/09'), findsOneWidget);
    await tester.tap(find.text('Lançamentos'));
    await settle(tester);
    expect(find.text('Aluguel'), findsOneWidget);
    expect(find.text(r'-R$ 1.500,00'), findsWidgets);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('Empréstimos: the rate fills the total; a partial payment brings profit in proportion', (tester) async {
    await pumpApp(tester, '/finance/loans');
    expect(find.text('Nenhum empréstimo ainda.'), findsOneWidget);
    await tester.tap(find.byTooltip('Novo empréstimo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Quem pegou emprestado'), 'João');
    await tester.enterText(find.widgetWithText(TextField, 'Valor emprestado'), '1000');
    await tester.enterText(find.widgetWithText(TextField, 'Juros'), '30');
    await tester.pump();
    expect(find.text('1.300,00'), findsOneWidget);
    expect(find.text(r'Lucro: R$ 300,00'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect(find.text('João'), findsOneWidget);
    expect(find.text(r'Falta R$ 1.300,00'), findsOneWidget);
    expect(find.text(r'lucro R$ 300,00 (30%)'), findsOneWidget);
    expect(find.textContaining('Em dia', findRichText: true), findsOneWidget);

    await tester.tap(find.text('João'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar pagamento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Valor pago'), '130');
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    // In the detail: received 130, of which 30 of profit; 1.170 left.
    Finder inDetail(String text) => find.descendant(of: find.byType(Dialog), matching: find.text(text));
    // "Recebido" and the payment.
    expect(inDetail(r'R$ 130,00'), findsNWidgets(2));
    expect(inDetail(r'R$ 30,00'), findsOneWidget);
    expect(inDetail(r'R$ 1.170,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Fechar'));
    await settle(tester);
    await dispose(tester);
  });

  testWidgets('Relatórios: by category, income × expenses, comparison and loans', (tester) async {
    final repo = FinanceRepository(db, clock: clock);
    await tester.runAsync(() async {
      final market = await repo.createCategory(name: 'Mercado', kind: FinKind.expense, icon: '🛒');
      await repo.addEntry(kind: FinKind.expense, amount: 40000, date: DateTime(2026, 8, 3), categoryId: market);
      await repo.addEntry(kind: FinKind.expense, amount: 60000, date: DateTime(2026, 9, 3), categoryId: market);
      await repo.addEntry(kind: FinKind.income, amount: 300000, date: DateTime(2026, 9, 1));
      await repo.createLoan(borrower: 'Ana', principal: 50000, total: 55000, lentOn: DateTime(2026, 9, 1), dueOn: DateTime(2026, 10, 1));
    });
    await pumpApp(tester, '/finance/reports');
    expect(find.text('Gastos por categoria'), findsOneWidget);
    expect(find.text('🛒 Mercado'), findsWidgets);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Receitas × despesas'), findsOneWidget);
    expect(find.text('Comparação entre meses'), findsOneWidget);
    // Mercado and the total.
    expect(find.text('+50%'), findsNWidgets(2));
    // The page's list (the tabs scroll sideways).
    await tester.scrollUntilVisible(
      find.text('A receber'),
      200,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first,
    );
    expect(find.text(r'R$ 550,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('phone: Finanças is in the drawer; the form takes the whole screen', (tester) async {
    await pumpApp(tester, '/q/all/tasks', size: const Size(560, 1000));
    await tester.tap(find.byIcon(Icons.menu_open).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finanças'));
    await settle(tester);
    expect(find.text('Lançamentos'), findsOneWidget);
    await tester.tap(find.byTooltip('Novo lançamento'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Dialog)).width, 560);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await dispose(tester);
  });
}
