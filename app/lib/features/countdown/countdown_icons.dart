import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Categories of the countdown's ready-made icons ("Evento, Pessoa, Festas, Esporte, Animal…").
enum CountdownIconCategory { event, person, party, sport, animal }

/// The ready-made icons of each category. TickTick draws its own pictures; here each one is an
/// emoji, kept in the same `icon` field as the "Emoji" and "Texto" choices.
const countdownIconSets = <CountdownIconCategory, List<String>>{
  CountdownIconCategory.event: ['📅', '⏰', '🎓', '💼', '✈️', '🏖️', '🏠', '💍', '💒', '🩺', '📚', '🚗', '🎤', '🎬', '🏆', '📝'],
  CountdownIconCategory.person: ['👶', '🧒', '👦', '👧', '🧑', '👨', '👩', '🧓', '👴', '👵', '👪', '💑', '👫', '🤱', '🧑‍🎓', '🧑‍💼'],
  CountdownIconCategory.party: ['🎂', '🎉', '🎊', '🎁', '🎈', '🎄', '🎃', '🎆', '🎇', '🥂', '🍾', '🪅', '🧧', '🕯️', '💝', '🌹'],
  CountdownIconCategory.sport: ['⚽', '🏀', '🏐', '🎾', '🏈', '⚾', '🏓', '🏸', '🏊', '🚴', '🏃', '🧘', '🏋️', '⛷️', '🥊', '🏄'],
  CountdownIconCategory.animal: ['🐶', '🐱', '🐰', '🐻', '🐼', '🦊', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐢', '🐠'],
};

String countdownIconCategoryLabel(AppLocalizations t, CountdownIconCategory c) => switch (c) {
  CountdownIconCategory.event => t.countdownIconEvent,
  CountdownIconCategory.person => t.countdownIconPerson,
  CountdownIconCategory.party => t.countdownIconParty,
  CountdownIconCategory.sport => t.countdownIconSport,
  CountdownIconCategory.animal => t.countdownIconAnimal,
};

/// The "Ícone" tab: one tab per category; returns the chosen icon, or null when closed.
Future<String?> showCountdownIconPicker(BuildContext context) => showDialog<String>(context: context, builder: (_) => const _IconPicker());

class _IconPicker extends StatelessWidget {
  const _IconPicker();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return AlertDialog(
      title: Text(t.countdownIcon, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      content: SizedBox(
        width: 360,
        height: 260,
        child: DefaultTabController(
          length: CountdownIconCategory.values.length,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: tt.primary,
                unselectedLabelColor: tt.textSecondary,
                tabs: [for (final c in CountdownIconCategory.values) Tab(text: countdownIconCategoryLabel(t, c), height: 36)],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final c in CountdownIconCategory.values)
                      GridView.extent(
                        maxCrossAxisExtent: 44,
                        padding: const EdgeInsets.only(top: 8),
                        children: [
                          for (final icon in countdownIconSets[c]!)
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => Navigator.pop(context, icon),
                              child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionClose))],
    );
  }
}
