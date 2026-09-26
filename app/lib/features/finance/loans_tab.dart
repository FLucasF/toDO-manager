import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../domain/finance/finance.dart';
import '../../domain/finance/loans.dart';
import '../../domain/finance/money.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import 'finance_widgets.dart';

enum _LoanFilter { open, overdue, paid, all }

/// "Empréstimos": the overview (lent, to receive, profit received, overdue), the loans with their
/// status, and each loan's payments.
class LoansTab extends ConsumerStatefulWidget {
  const LoansTab({super.key});

  @override
  ConsumerState<LoansTab> createState() => _LoansTabState();
}

class _LoansTabState extends ConsumerState<LoansTab> {
  _LoanFilter _filter = _LoanFilter.open;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());
    final loans = loanSummaries(s, today);
    final shown = [
      for (final l in loans)
        if (switch (_filter) {
          _LoanFilter.open => l.status != LoanStatus.paid,
          _LoanFilter.overdue => l.status == LoanStatus.overdue,
          _LoanFilter.paid => l.status == LoanStatus.paid,
          _LoanFilter.all => true,
        })
          l,
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 8, narrow ? 12 : 20, 32),
      children: [
        LoansOverviewCards(overview: loansOverview(loans)),
        const SizedBox(height: 12),
        // "Novo empréstimo" is the "+" of the header.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (f, label) in [
                (_LoanFilter.open, t.finLoansOpen),
                (_LoanFilter.overdue, t.finLoansOverdue),
                (_LoanFilter.paid, t.finLoansPaid),
                (_LoanFilter.all, t.finLoansAll),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FinChip(label: label, selected: _filter == f, onTap: () => setState(() => _filter = f)),
                ),
            ],
          ),
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              loans.isEmpty ? t.finNoLoans : t.finNoLoansHere,
              textAlign: TextAlign.center,
              style: TextStyle(color: tt.textTertiary),
            ),
          ),
        for (final l in shown) _LoanRow(summary: l),
      ],
    );
  }
}

/// The four numbers of the loans (also on Relatórios).
class LoansOverviewCards extends StatelessWidget {
  const LoansOverviewCards({super.key, required this.overview});

  final LoansOverview overview;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    Widget card(String label, int cents, Color color, String? hint) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(cents),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          if (hint != null)
            Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: tt.textTertiary),
            ),
        ],
      ),
    );
    final cards = [
      card(t.finLentOpen, overview.lentOpen, tt.text, t.finLoansCount(overview.open)),
      card(t.finToReceive, overview.toReceive, tt.primary, t.finInterestToCome(formatMoney(overview.interestToCome))),
      card(t.finInterestReceived, overview.interestReceived, tt.palette.green, t.finLentTotal(formatMoney(overview.lentTotal))),
      card(t.finOverdueAmount, overview.overdue, overview.overdue > 0 ? tt.overdue : tt.text, t.finLoansCount(overview.overdueCount)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth < 560 ? 2 : 4;
        final width = (constraints.maxWidth - 8 * (perRow - 1)) / perRow;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final c in cards) SizedBox(width: width, child: c)],
        );
      },
    );
  }
}

/// "Em dia", "Atrasado há N dias", "Quitado" and its color.
(String, Color) loanStatusLabel(BuildContext context, LoanSummary l) {
  final t = AppLocalizations.of(context);
  final tt = context.tt;
  return switch (l.status) {
    LoanStatus.onTime => (t.finLoanOnTime, tt.primary),
    LoanStatus.overdue => (t.finLoanLate(l.daysLate), tt.overdue),
    LoanStatus.paid => (t.finLoanPaid, tt.palette.green),
  };
}

class _LoanRow extends StatelessWidget {
  const _LoanRow({required this.summary});

  final LoanSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final loan = summary.loan;
    final (status, color) = loanStatusLabel(context, summary);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => unawaited(showLoanDetail(context, loan.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: tt.fieldFill,
              child: Text(
                loan.borrower.isEmpty ? '?' : loan.borrower.characters.first.toUpperCase(),
                style: TextStyle(color: tt.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.borrower,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tt.text, fontSize: TtText.body),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: status,
                          style: TextStyle(color: color, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' · ${t.finDueOn(DateLabels.numeric(finDay(loan.dueOn)))}'),
                      ],
                    ),
                    style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  summary.status == LoanStatus.paid ? formatMoney(loan.total) : t.finLoanLeft(formatMoney(summary.balance)),
                  style: TextStyle(color: tt.text, fontWeight: FontWeight.w600),
                ),
                Text(
                  t.finProfit(formatMoney(summary.interest), formatPercent(summary.rate)),
                  style: TextStyle(fontSize: TtText.small, color: tt.palette.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A loan: its numbers, its payments, "Registrar pagamento", Editar and Excluir.
Future<void> showLoanDetail(BuildContext context, String loanId) => showFinanceDialog<void>(context, builder: (_) => _LoanDetail(loanId: loanId));

class _LoanDetail extends ConsumerWidget {
  const _LoanDetail({required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());
    final summary = loanSummaries(s, today).where((l) => l.loan.id == loanId).firstOrNull;
    if (summary == null) return const SizedBox.shrink();
    final loan = summary.loan;
    final repo = ref.read(financeRepositoryProvider);
    final (status, color) = loanStatusLabel(context, summary);

    Widget line(String label, String value, {Color? valueColor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: tt.textSecondary)),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor ?? tt.text, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(loan.borrower, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                tooltip: t.actionEdit,
                icon: Icon(Icons.edit_outlined, color: tt.textSecondary),
                onPressed: () => unawaited(showLoanForm(context, editing: summary)),
              ),
              IconButton(
                tooltip: t.actionDelete,
                icon: Icon(Icons.delete_outline, color: tt.textSecondary),
                onPressed: () async {
                  if (!await confirm(context, message: t.finDeleteLoan(loan.borrower), confirmLabel: t.actionDelete)) return;
                  await repo.deleteLoan(loan.id);
                  if (!context.mounted) return;
                  final pageContext = Navigator.of(context).context;
                  Navigator.pop(context);
                  if (pageContext.mounted) {
                    showToast(pageContext, t.finLoanDeleted, undo: () => repo.restoreLoan(loan.id), redo: () => repo.deleteLoan(loan.id));
                  }
                },
              ),
              IconButton(
                tooltip: t.actionClose,
                icon: Icon(Icons.close, color: tt.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(
                status,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              line(t.finLent, formatMoney(loan.principal)),
              line(t.finLoanTotal, formatMoney(loan.total)),
              line(t.finProfitLabel, '${formatMoney(summary.interest)} (${formatPercent(summary.rate)})', valueColor: tt.palette.green),
              line(t.finReceived, formatMoney(summary.received)),
              line(t.finInterestReceived, formatMoney(summary.interestReceived), valueColor: tt.palette.green),
              line(t.finLoanBalance, formatMoney(summary.balance), valueColor: summary.balance > 0 ? tt.overdue : null),
              line(t.finLentOn, DateLabels.numeric(finDay(loan.lentOn))),
              line(t.finDueDate, DateLabels.numeric(finDay(loan.dueOn))),
              if (loan.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(loan.note, style: TextStyle(color: tt.textSecondary)),
                ),
              const SizedBox(height: 16),
              if (summary.balance > 0)
                FilledButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t.finAddLoanPayment),
                  onPressed: () => unawaited(showFinanceDialog<void>(context, builder: (_) => _LoanPaymentForm(summary: summary))),
                ),
              if (summary.payments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                  child: Text(
                    t.finPayments,
                    style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w600, color: tt.textSecondary),
                  ),
                ),
              for (final p in summary.payments)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle_outline, color: tt.palette.green),
                  title: Text(formatMoney(p.amount), style: TextStyle(color: tt.text)),
                  subtitle: Text(
                    [DateLabels.numeric(finDay(p.date)), if (p.note.isNotEmpty) p.note].join(' · '),
                    style: TextStyle(color: tt.textTertiary),
                  ),
                  trailing: IconButton(
                    tooltip: t.actionDelete,
                    icon: Icon(Icons.close, size: 18, color: tt.textTertiary),
                    onPressed: () async {
                      await repo.deleteLoanPayment(p.id);
                      if (context.mounted) {
                        showToast(
                          context,
                          t.finPaymentDeleted,
                          undo: () => repo.deleteLoanPayment(p.id, restore: true),
                          redo: () => repo.deleteLoanPayment(p.id),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoanPaymentForm extends ConsumerStatefulWidget {
  const _LoanPaymentForm({required this.summary});

  final LoanSummary summary;

  @override
  ConsumerState<_LoanPaymentForm> createState() => _LoanPaymentFormState();
}

class _LoanPaymentFormState extends ConsumerState<_LoanPaymentForm> {
  late final _amount = TextEditingController(text: formatMoney(widget.summary.balance, symbol: false));
  final _note = TextEditingController();
  late DateTime _date = startOfDay(ref.read(clockProvider).now());

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseMoney(_amount.text);
    if (amount == null || amount <= 0) return;
    await ref.read(financeRepositoryProvider).addLoanPayment(loanId: widget.summary.loan.id, amount: amount, date: _date, note: _note.text);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(title: t.finAddLoanPayment, onSave: () => unawaited(_save())),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.finLoanLeft(formatMoney(widget.summary.balance)), style: TextStyle(color: tt.textSecondary)),
              const SizedBox(height: 8),
              MoneyField(controller: _amount, label: t.finPaymentAmount, autofocus: true, onSubmitted: () => unawaited(_save())),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today_outlined, color: tt.textSecondary),
                title: Text(
                  t.finPaymentDate,
                  style: TextStyle(color: tt.textSecondary, fontSize: TtText.small),
                ),
                subtitle: Text(DateLabels.numeric(_date), style: TextStyle(color: tt.text)),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              TextField(
                controller: _note,
                decoration: InputDecoration(labelText: t.finNote, isDense: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Novo empréstimo" / "Editar empréstimo": the borrower, the amount lent and when, the due day,
/// and the interest either as a rate or as the total to receive (each fills the other in); the
/// profit shows below.
Future<void> showLoanForm(BuildContext context, {LoanSummary? editing}) =>
    showFinanceDialog<void>(context, builder: (_) => _LoanForm(editing: editing));

class _LoanForm extends ConsumerStatefulWidget {
  const _LoanForm({this.editing});

  final LoanSummary? editing;

  @override
  ConsumerState<_LoanForm> createState() => _LoanFormState();
}

class _LoanFormState extends ConsumerState<_LoanForm> {
  late final _loan = widget.editing?.loan;
  late final _borrower = TextEditingController(text: _loan?.borrower ?? '');
  late final _principal = TextEditingController(text: _loan == null ? '' : formatMoney(_loan.principal, symbol: false));
  late final _rate = TextEditingController(text: widget.editing == null ? '' : formatPercent(widget.editing!.rate).replaceAll('%', ''));
  late final _total = TextEditingController(text: _loan == null ? '' : formatMoney(_loan.total, symbol: false));
  late final _note = TextEditingController(text: _loan?.note ?? '');
  late DateTime _lentOn = _loan == null ? startOfDay(ref.read(clockProvider).now()) : finDay(_loan.lentOn);
  late DateTime _dueOn = _loan == null ? DateTime(_lentOn.year, _lentOn.month + 1, _lentOn.day) : finDay(_loan.dueOn);
  late bool _remind = _loan?.remind ?? true;
  bool _showError = false;

  @override
  void dispose() {
    for (final c in [_borrower, _principal, _rate, _total, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The rate typed: the total follows.
  void _fromRate() {
    final principal = parseMoney(_principal.text), rate = parsePercent(_rate.text);
    if (principal == null || rate == null) return setState(() {});
    _total.text = formatMoney(principal + (principal * rate / 10000).round(), symbol: false);
    setState(() => _showError = false);
  }

  /// The total typed: the rate follows.
  void _fromTotal() {
    final principal = parseMoney(_principal.text), total = parseMoney(_total.text);
    if (principal == null || principal == 0 || total == null) return setState(() {});
    _rate.text = formatPercent(((total - principal) * 10000 / principal).round()).replaceAll('%', '');
    setState(() => _showError = false);
  }

  Future<void> _save() async {
    final principal = parseMoney(_principal.text), total = parseMoney(_total.text);
    final borrower = _borrower.text.trim();
    if (borrower.isEmpty || principal == null || principal <= 0 || total == null || total < principal) {
      setState(() => _showError = true);
      return;
    }
    final repo = ref.read(financeRepositoryProvider);
    final loan = _loan;
    if (loan == null) {
      await repo.createLoan(
        borrower: borrower,
        principal: principal,
        total: total,
        lentOn: _lentOn,
        dueOn: _dueOn,
        note: _note.text,
        remind: _remind,
      );
    } else {
      await repo.updateLoan(
        loan.id,
        borrower: borrower,
        principal: principal,
        total: total,
        lentOn: _lentOn,
        dueOn: _dueOn,
        note: _note.text,
        remind: _remind,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final principal = parseMoney(_principal.text), total = parseMoney(_total.text);
    final profit = principal == null || total == null ? null : total - principal;

    Widget dateTile(String label, DateTime value, ValueChanged<DateTime> onPicked) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.event_outlined, color: tt.textSecondary),
      title: Text(
        label,
        style: TextStyle(color: tt.textSecondary, fontSize: TtText.small),
      ),
      subtitle: Text(DateLabels.numeric(value), style: TextStyle(color: tt.text)),
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (picked != null) setState(() => onPicked(picked));
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(title: _loan == null ? t.finNewLoan : t.finEditLoan, onSave: () => unawaited(_save())),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              TextField(
                controller: _borrower,
                autofocus: _loan == null,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: t.finBorrower, isDense: true),
              ),
              const SizedBox(height: 8),
              MoneyField(controller: _principal, label: t.finLent, onChanged: (_) => _rate.text.isEmpty ? _fromTotal() : _fromRate()),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rate,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: t.finInterestRate, suffixText: '%', isDense: true),
                      onChanged: (_) => _fromRate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MoneyField(controller: _total, label: t.finLoanTotal, onChanged: (_) => _fromTotal()),
                  ),
                ],
              ),
              if (profit != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    t.finProfitPreview(formatMoney(profit)),
                    style: TextStyle(color: profit < 0 ? tt.overdue : tt.palette.green, fontWeight: FontWeight.w600),
                  ),
                ),
              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    t.finLoanInvalid,
                    style: TextStyle(color: tt.overdue, fontSize: TtText.small),
                  ),
                ),
              dateTile(t.finLentOn, _lentOn, (d) => _lentOn = d),
              dateTile(t.finDueDate, _dueOn, (d) => _dueOn = d),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.finLoanRemind),
                value: _remind,
                onChanged: (v) => setState(() => _remind = v),
              ),
              TextField(
                controller: _note,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(labelText: t.finNote, isDense: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
