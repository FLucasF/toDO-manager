/// "Adiar" options of the reminder popup: 15 min · 30 min · 1 h · 3 h · Hoje à noite ·
/// Amanhã · Personalizado.
enum SnoozeOption { minutes15, minutes30, hour1, hours3, tonight, tomorrow }

/// "Hoje à noite" and "Amanhã" times. Not observed in TickTick; 20:00 and 09:00 are assumptions.
const tonightHour = 20;
const tomorrowHour = 9;

/// When the reminder fires again, or null when the option makes no sense now ("Hoje à noite" after 20:00).
DateTime? snoozeTime(SnoozeOption option, DateTime now) => switch (option) {
  SnoozeOption.minutes15 => now.add(const Duration(minutes: 15)),
  SnoozeOption.minutes30 => now.add(const Duration(minutes: 30)),
  SnoozeOption.hour1 => now.add(const Duration(hours: 1)),
  SnoozeOption.hours3 => now.add(const Duration(hours: 3)),
  SnoozeOption.tonight => now.hour < tonightHour ? DateTime(now.year, now.month, now.day, tonightHour) : null,
  SnoozeOption.tomorrow => DateTime(now.year, now.month, now.day + 1, tomorrowHour),
};
