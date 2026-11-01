import '../../l10n/app_localizations.dart';

const _storedWeekdays = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Traduce un día de célula guardado en español al idioma activo.
String? localizedWeekday(AppLocalizations l10n, String? storedValue) {
  if (storedValue == null || storedValue.trim().isEmpty) return storedValue;
  final index = _storedWeekdays.indexOf(storedValue.trim());
  if (index < 0) return storedValue;
  return switch (index) {
    0 => l10n.weekdayMonday,
    1 => l10n.weekdayTuesday,
    2 => l10n.weekdayWednesday,
    3 => l10n.weekdayThursday,
    4 => l10n.weekdayFriday,
    5 => l10n.weekdaySaturday,
    6 => l10n.weekdaySunday,
    _ => storedValue,
  };
}

const cellWeekdayStorageValues = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Día de la semana en el formato guardado en Firestore (`cellDay`).
String weekdayStorageValueFromDate(DateTime date) {
  return cellWeekdayStorageValues[date.weekday - 1];
}

bool weekdayDiffersFromStored(DateTime date, String? storedCellDay) {
  final stored = storedCellDay?.trim();
  if (stored == null || stored.isEmpty) return false;
  return weekdayStorageValueFromDate(date) != stored;
}
