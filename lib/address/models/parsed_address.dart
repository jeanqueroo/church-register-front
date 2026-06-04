class ParsedAddress {
  const ParsedAddress({
    this.street,
    this.streetNumber,
    this.neighborhood,
    this.locality,
    this.stateProvince,
    this.postalCode,
  });

  final String? street;
  final String? streetNumber;
  final String? neighborhood;
  final String? locality;
  final String? stateProvince;
  final String? postalCode;

  static ParsedAddress fromGoogleAddressComponents(List<dynamic> components) {
    String? component(String type, {bool short = false}) {
      for (final item in components) {
        final map = item as Map<String, dynamic>;
        final types = (map['types'] as List<dynamic>).cast<String>();
        if (types.contains(type)) {
          final value = (short ? map['short_name'] : map['long_name']) as String?;
          if (value != null && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
      return null;
    }

    var street = component('route');
    var streetNumber = component('street_number');

    if (street != null) {
      final split = splitStreetAndNumber(street);
      if (streetNumber == null && split.number != null) {
        streetNumber = split.number;
      }
      street = split.street;
    }

    return ParsedAddress(
      street: street,
      streetNumber: streetNumber,
      neighborhood: component('neighborhood') ??
          component('sublocality') ??
          component('sublocality_level_1'),
      locality: component('locality') ??
          component('administrative_area_level_2'),
      stateProvince: component('administrative_area_level_1'),
      postalCode: component('postal_code'),
    );
  }

  static ParsedAddress fromNominatim(
    Map<String, dynamic>? address, {
    String? displayName,
  }) {
    var street = _firstValue(address, const [
      'road',
      'pedestrian',
      'street',
      'residential',
      'footway',
      'path',
      'hamlet',
      'avenue',
      'boulevard',
    ]);
    var streetNumber = _firstValue(address, const [
      'house_number',
      'house_name',
    ]);

    if (street != null) {
      final split = splitStreetAndNumber(street);
      if (streetNumber == null && split.number != null) {
        streetNumber = split.number;
      }
      street = split.street;
    }

    if (streetNumber == null && displayName != null) {
      final fromDisplay = _extractFromDisplayName(displayName);
      streetNumber = fromDisplay.number;
      if (street == null || street.isEmpty) {
        street = fromDisplay.street;
      }
    }

    return ParsedAddress(
      street: street,
      streetNumber: streetNumber,
      neighborhood: _firstValue(address, const [
        'suburb',
        'neighbourhood',
        'neighborhood',
        'quarter',
        'city_district',
        'borough',
      ]),
      locality: _firstValue(address, const [
        'city',
        'town',
        'village',
        'municipality',
        'county',
        'state_district',
      ]),
      stateProvince: _firstValue(address, const ['state', 'region']),
      postalCode: _firstValue(address, const ['postcode']),
    );
  }

  /// Separa "Av. Corrientes 1500" o "1500 Av. Corrientes" en calle y número.
  static ({String street, String? number}) splitStreetAndNumber(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return (street: '', number: null);
    }

    // Número al final: "Calle Falsa 123" / "Av. San Martín 1500 B"
    final endNumber = RegExp(
      r'^(.+?)\s+(\d{1,6}[a-zA-Z]?(?:\s*[-/]\s*\d{1,4}[a-zA-Z]?)?)$',
    ).firstMatch(trimmed);
    if (endNumber != null) {
      return (
        street: endNumber.group(1)!.trim(),
        number: endNumber.group(2)!.trim(),
      );
    }

    // Número al inicio: "1500 Avenida Corrientes" o "1500, Corrientes"
    final startNumber = RegExp(
      r'^(\d{1,6}[a-zA-Z]?)\s*,?\s+(.+)$',
    ).firstMatch(trimmed);
    if (startNumber != null) {
      return (
        street: startNumber.group(2)!.trim(),
        number: startNumber.group(1)!.trim(),
      );
    }

    return (street: trimmed, number: null);
  }

  static ({String? street, String? number}) _extractFromDisplayName(
    String displayName,
  ) {
    final firstSegment = displayName.split(',').first.trim();
    if (firstSegment.isEmpty) {
      return (street: null, number: null);
    }
    final split = splitStreetAndNumber(firstSegment);
    return (street: split.street, number: split.number);
  }

  static String? _firstValue(
    Map<String, dynamic>? address,
    List<String> keys,
  ) {
    if (address == null) return null;
    for (final key in keys) {
      final value = address[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
