import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/features/habits/habit_gallery.dart';
import 'package:task_manager/l10n/app_localizations_pt.dart';

void main() {
  test('the gallery has four categories of 15 habits, each with its emoji', () {
    final t = AppLocalizationsPt();
    for (final lines in [t.habitGalleryLifeItems, t.habitGalleryHealthItems, t.habitGalleryExerciseItems, t.habitGalleryMindItems]) {
      final presets = habitPresets(lines);
      expect(presets, hasLength(15));
      expect(presets.every((p) => p.icon.isNotEmpty && p.name.isNotEmpty && !p.name.contains(p.icon)), isTrue);
    }
    expect(habitPresets(t.habitGalleryHealthItems).first, (icon: '💧', name: 'Beber água'));
  });
}
