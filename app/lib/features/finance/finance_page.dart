import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../data/finance_repository.dart';
import '../../data/preferences_repository.dart';
import '../../domain/finance/finance_enums.dart';
import '../../l10n/app_localizations.dart';
import '../shell/app_shell.dart';
import 'cards_tab.dart';
import 'categories_tab.dart';
import 'entries_tab.dart';
import 'entry_form.dart';
import 'loans_tab.dart';
import 'recurring_tab.dart';
import 'reports_tab.dart';

/// Tabs of Finanças (`/finance/{tab}`).
enum FinanceTab {
  entries('entries'),
  cards('cards'),
  recurring('recurring'),
  loans('loans'),
  reports('reports'),
  categories('categories');

  const FinanceTab(this.route);
  final String route;

  static FinanceTab fromRoute(String? route) => values.where((t) => t.route == route).firstOrNull ?? entries;
}

/// The default categories, created the first time Finanças opens.
Future<void> seedFinanceCategories(FinanceRepository repo, PreferencesRepository prefs, AppLocalizations t) async {
  if (await prefs.financeCategoriesSeeded()) return;
  await repo.seedCategories([
    (name: t.finCatFood, icon: '🍽️', kind: FinKind.expense),
    (name: t.finCatMarket, icon: '🛒', kind: FinKind.expense),
    (name: t.finCatTransport, icon: '🚗', kind: FinKind.expense),
    (name: t.finCatHome, icon: '🏠', kind: FinKind.expense),
    (name: t.finCatBills, icon: '💡', kind: FinKind.expense),
    (name: t.finCatHealth, icon: '💊', kind: FinKind.expense),
    (name: t.finCatEducation, icon: '📚', kind: FinKind.expense),
    (name: t.finCatLeisure, icon: '🎉', kind: FinKind.expense),
    (name: t.finCatShopping, icon: '🛍️', kind: FinKind.expense),
    (name: t.finCatSubscriptions, icon: '📺', kind: FinKind.expense),
    (name: t.finCatOther, icon: '📦', kind: FinKind.expense),
    (name: t.finCatSalary, icon: '💰', kind: FinKind.income),
    (name: t.finCatExtra, icon: '💵', kind: FinKind.income),
    (name: t.finCatOther, icon: '📦', kind: FinKind.income),
  ]);
  await prefs.markFinanceCategoriesSeeded();
}

/// Finanças: Lançamentos · Cartões · Contas fixas · Empréstimos · Relatórios · Categorias.
class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key, required this.tab});

  final FinanceTab tab;

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(seedFinanceCategories(ref.read(financeRepositoryProvider), ref.read(preferencesRepositoryProvider), AppLocalizations.of(context)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    Widget tabButton(FinanceTab value, String label) => TextButton(
      onPressed: () => context.go(Routes.financeOf(value.route)),
      style: TextButton.styleFrom(foregroundColor: value == widget.tab ? tt.primary : tt.textSecondary),
      child: Text(label, style: TextStyle(fontSize: 15, fontWeight: value == widget.tab ? FontWeight.w700 : FontWeight.w400)),
    );

    final page = Container(
      color: tt.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 14, 16, 0),
            child: Row(
              children: [
                const DrawerMenuButton(),
                Expanded(
                  child: Text(
                    t.navFinance,
                    style: TextStyle(fontSize: TtText.listTitle, fontWeight: FontWeight.w600, color: tt.text),
                  ),
                ),
                // "+" adds what the tab shows: a bill, a loan, a category, or else an entry.
                IconButton(
                  tooltip: switch (widget.tab) {
                    FinanceTab.recurring => t.finNewRecurring,
                    FinanceTab.loans => t.finNewLoan,
                    FinanceTab.categories => t.finNewCategory,
                    _ => t.finNewEntry,
                  },
                  icon: Icon(Icons.add, color: tt.textSecondary),
                  onPressed: () => unawaited(switch (widget.tab) {
                    FinanceTab.recurring => showRecurringForm(context),
                    FinanceTab.loans => showLoanForm(context),
                    FinanceTab.categories => showCategoryForm(context, kind: FinKind.expense),
                    _ => showEntryForm(context),
                  }),
                ),
              ],
            ),
          ),
          // Tabs scroll sideways on a phone.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: narrow ? 4 : 12),
            child: Row(
              children: [
                tabButton(FinanceTab.entries, t.finTabEntries),
                tabButton(FinanceTab.cards, t.finTabCards),
                tabButton(FinanceTab.recurring, t.finTabRecurring),
                tabButton(FinanceTab.loans, t.finTabLoans),
                tabButton(FinanceTab.reports, t.finTabReports),
                tabButton(FinanceTab.categories, t.finTabCategories),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: switch (widget.tab) {
                  FinanceTab.entries => const EntriesTab(),
                  FinanceTab.cards => const CardsTab(),
                  FinanceTab.recurring => const RecurringTab(),
                  FinanceTab.loans => const LoansTab(),
                  FinanceTab.reports => const ReportsTab(),
                  FinanceTab.categories => const CategoriesTab(),
                },
              ),
            ),
          ),
        ],
      ),
    );
    return ModuleScaffold(module: AppModule.finance, child: page);
  }
}
