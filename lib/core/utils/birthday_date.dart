/// Utilidades para fechas de nacimiento y cumpleaños del día.
class BirthdayDate {
  const BirthdayDate._();

  /// Fecha civil (sin hora) en hora local.
  static DateTime? normalize(DateTime? date) {
    if (date == null) return null;
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// `true` si el mes y día coinciden con [reference] (por defecto hoy).
  static bool isToday(DateTime? birthDate, [DateTime? reference]) {
    if (birthDate == null) return false;

    final today = normalize(reference ?? DateTime.now());
    if (today == null) return false;

    final localBirth = normalize(birthDate);
    if (localBirth != null &&
        localBirth.month == today.month &&
        localBirth.day == today.day) {
      return true;
    }

    // Fechas importadas como día civil en UTC (medianoche exacta).
    final utc = birthDate.toUtc();
    final isUtcMidnight = utc.hour == 0 &&
        utc.minute == 0 &&
        utc.second == 0 &&
        utc.millisecond == 0;
    if (isUtcMidnight &&
        utc.month == today.month &&
        utc.day == today.day) {
      return true;
    }

    return false;
  }
}
