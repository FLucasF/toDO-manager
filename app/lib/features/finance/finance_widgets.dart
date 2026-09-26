import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../domain/finance/finance_enums.dart';
import '../../domain/finance/money.dart';
import '../../l10n/app_localizations.dart';

/// Green for money in, red for money out.
Color finKindColor(BuildContext context, FinKind kind) => kind == FinKind.income ? context.tt.palette.green : context.tt.overdue;

/// "+R$ 5.000,00" / "-R$ 120,00".
String signedMoney(FinKind kind, int cents) => '${kind == FinKind.income ? '+' : '-'}${formatMoney(cents)}';

/// A category's emoji on a soft circle; "Sem categoria" gets a dash.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.size = 32});

  final FinCategory? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final icon = category?.icon ?? '';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tt.fieldFill, shape: BoxShape.circle),
      child: icon.isEmpty ? Icon(Icons.remove, size: size * 0.5, color: tt.textTertiary) : Text(icon, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// The name of a category, or "Sem categoria".
String categoryName(AppLocalizations t, FinCategory? c) => c?.name ?? t.finNoCategory;

/// A text field for reais: numeric keyboard, "R$" before; [onChanged] gets the typed cents (null
/// when it is not an amount).
class MoneyField extends StatelessWidget {
  const MoneyField({super.key, required this.controller, required this.label, this.autofocus = false, this.onChanged, this.onSubmitted});

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final ValueChanged<int?>? onChanged;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, prefixText: r'R$ ', isDense: true),
    onChanged: onChanged == null ? null : (text) => onChanged!(parseMoney(text)),
    onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
  );
}

/// A form in a dialog, or on the whole screen on a phone.
Future<T?> showFinanceDialog<T>(BuildContext context, {required WidgetBuilder builder}) => showDialog<T>(
  context: context,
  builder: (context) {
    if (MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint) {
      return Dialog.fullscreen(child: SafeArea(child: builder(context)));
    }
    return Dialog(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460, maxHeight: 720), child: builder(context)),
    );
  },
);

/// The top of a finance form: title, Cancelar and Salvar.
class FormHeader extends StatelessWidget {
  const FormHeader({super.key, required this.title, required this.onSave});

  final String title;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
          const SizedBox(width: 4),
          FilledButton(onPressed: onSave, child: Text(t.actionSave)),
        ],
      ),
    );
  }
}

/// A chip of the finance tabs, selected in the app's blue.
class FinChip extends StatelessWidget {
  const FinChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return ChoiceChip(
      label: Text(label),
      avatar: icon == null ? null : Icon(icon, size: 16, color: selected ? tt.primary : tt.textSecondary),
      selected: selected,
      showCheckmark: false,
      selectedColor: tt.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: selected ? tt.primary : tt.text, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
      side: BorderSide(color: selected ? tt.primary.withValues(alpha: 0.4) : tt.divider),
      onSelected: (_) => onTap(),
    );
  }
}
