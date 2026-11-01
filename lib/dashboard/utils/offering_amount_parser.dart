double parseOfferingAmount(String? raw) {
  if (raw == null) return 0;
  var value = raw.trim();
  if (value.isEmpty) return 0;

  value = value.replaceAll(RegExp(r'[^\d,.\-]'), '');
  if (value.isEmpty) return 0;

  if (value.contains(',') && value.contains('.')) {
    value = value.replaceAll('.', '').replaceAll(',', '.');
  } else if (value.contains(',')) {
    value = value.replaceAll(',', '.');
  }

  return double.tryParse(value) ?? 0;
}
