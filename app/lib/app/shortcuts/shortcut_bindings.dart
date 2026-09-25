import 'shortcut_resolver.dart';

/// The keys of an action, as text (Settings → Atalhos):
/// - `Ctrl+K`, `Ctrl+Shift+P`, `Alt+1`, `Ctrl+Delete`: modifiers and a key;
/// - `Tab+N`: a key pressed while Tab is held;
/// - `G T`: two keys in sequence ("G→T");
/// - `N`, `/`, `?`: one key.
/// Esc and Enter are not bindings: they always cancel and add.
abstract final class ShortcutBindings {
  /// TickTick's defaults.
  static const defaults = <ShortcutAction, List<String>>{
    ShortcutAction.palette: ['Ctrl+K'],
    ShortcutAction.print: ['Ctrl+P'],
    ShortcutAction.undo: ['Ctrl+Z'],
    ShortcutAction.redo: ['Ctrl+Shift+Z'],
    ShortcutAction.focusToggle: ['Ctrl+Shift+P'],
    ShortcutAction.help: ['?'],
    ShortcutAction.search: ['/'],
    ShortcutAction.addTask: ['Tab+N', 'N'],
    ShortcutAction.toggleSubtasks: ['Tab+E'],
    ShortcutAction.complete: ['Tab+M'],
    ShortcutAction.pin: ['Tab+P'],
    ShortcutAction.delete: ['Ctrl+Delete'],
    ShortcutAction.setDate: ['Tab+D'],
    ShortcutAction.noDate: ['Tab+0'],
    ShortcutAction.today: ['Tab+1'],
    ShortcutAction.tomorrow: ['Tab+2'],
    ShortcutAction.nextWeek: ['Tab+3'],
    ShortcutAction.priorityNone: ['Alt+0'],
    ShortcutAction.priorityLow: ['Alt+1'],
    ShortcutAction.priorityMedium: ['Alt+2'],
    ShortcutAction.priorityHigh: ['Alt+3'],
    ShortcutAction.goAll: ['G A'],
    ShortcutAction.goToday: ['G T'],
    ShortcutAction.goTomorrow: ['G R'],
    ShortcutAction.goNext7Days: ['G N'],
    ShortcutAction.goInbox: ['G I'],
    ShortcutAction.goCompleted: ['G C'],
    ShortcutAction.goWontDo: ['G W'],
    ShortcutAction.goSummary: ['G B'],
    ShortcutAction.goTrash: ['G G'],
    ShortcutAction.goSettings: ['G S'],
    ShortcutAction.viewList: ['V L'],
    ShortcutAction.viewKanban: ['V K'],
    ShortcutAction.viewTimeline: ['V T'],
  };

  /// The defaults with the user's changes ([custom]: action name → its keys; an empty list = none).
  static Map<ShortcutAction, List<String>> merged(Map<String, List<String>> custom) => {
    for (final e in defaults.entries) e.key: custom[e.key.name] ?? e.value,
  };

  /// A binding in its canonical form ("ctrl+shift+p", "tab+n", "g t", "n", "/"), or null when invalid.
  static String? normalize(String binding) {
    final text = binding.trim();
    if (text.isEmpty) return null;
    if (text.contains(' ')) {
      final keys = text.toLowerCase().split(RegExp(r'\s+'));
      return keys.length == 2 && keys.every((k) => RegExp(r'^[a-z0-9]$').hasMatch(k)) ? keys.join(' ') : null;
    }
    if (text.length == 1) return text.toLowerCase();
    final parts = text.split('+').map((p) => p.trim().toLowerCase()).toList();
    final key = parts.removeLast();
    if (key.isEmpty || parts.isEmpty) return null;
    const order = ['ctrl', 'shift', 'alt', 'tab'];
    if (!parts.every(order.contains)) return null;
    if (parts.contains('tab') && parts.length > 1) return null;
    return [
      for (final m in order)
        if (parts.contains(m)) m,
      key,
    ].join('+');
  }

  /// How a binding is shown: "Ctrl+Shift+P", "Tab+N", "G→T", "?".
  static String display(String binding) {
    final n = normalize(binding) ?? binding;
    if (n.contains(' ')) return n.split(' ').map((k) => k.toUpperCase()).join('→');
    if (!n.contains('+')) return n.toUpperCase();
    return n.split('+').map((p) => p.length == 1 ? p.toUpperCase() : '${p[0].toUpperCase()}${p.substring(1)}').join('+');
  }
}
