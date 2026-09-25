import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'habit_form.dart';

/// A ready-made habit of the gallery: its emoji and name.
typedef HabitPreset = ({String icon, String name});

/// The presets of a category, from its PT-BR text ("🌅 Acordar cedo" per line).
List<HabitPreset> habitPresets(String lines) => [
  for (final line in lines.split('\n'))
    if (line.trim().indexOf(' ') case final space when space > 0)
      (icon: line.trim().substring(0, space), name: line.trim().substring(space + 1).trim()),
];

/// "Galeria de hábitos": ready-made habits in four categories, or "Criar novo".
Future<void> showHabitGallery(BuildContext context) async {
  final choice = await showDialog<Object>(context: context, builder: (_) => const _HabitGallery());
  if (!context.mounted || choice == null) return;
  await showHabitForm(context, preset: choice is HabitPreset ? choice : null);
}

class _HabitGallery extends StatefulWidget {
  const _HabitGallery();

  @override
  State<_HabitGallery> createState() => _HabitGalleryState();
}

class _HabitGalleryState extends State<_HabitGallery> {
  int _category = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final categories = [
      (t.habitGalleryLife, t.habitGalleryLifeItems),
      (t.habitGalleryHealth, t.habitGalleryHealthItems),
      (t.habitGalleryExercise, t.habitGalleryExerciseItems),
      (t.habitGalleryMind, t.habitGalleryMindItems),
    ];
    final presets = habitPresets(categories[_category].$2);
    return AlertDialog(
      title: Text(t.habitGallery, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 560,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              children: [
                for (final (i, (label, _)) in categories.indexed)
                  ChoiceChip(label: Text(label), selected: _category == i, showCheckmark: false, onSelected: (_) => setState(() => _category = i)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.extent(
                maxCrossAxisExtent: 170,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.4,
                children: [
                  for (final p in presets)
                    Material(
                      color: tt.fieldFill,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.pop(context, p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Text(p.icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: tt.text),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, 'new'), child: Text(t.habitCreateNew)),
      ],
    );
  }
}
