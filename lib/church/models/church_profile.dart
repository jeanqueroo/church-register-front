import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil de la iglesia (documento único en `churches/main`).
class ChurchProfile {
  const ChurchProfile({
    required this.name,
    required this.address,
    this.logoUrl,
    this.alias,
    this.latitude,
    this.longitude,
    this.isBlocked = false,
    this.updatedAt,
    this.updatedBy,
  });

  final String name;
  final String address;
  final String? logoUrl;
  /// Alias bancario para transferencias.
  final String? alias;
  final double? latitude;
  final double? longitude;
  final bool isBlocked;
  final DateTime? updatedAt;
  final String? updatedBy;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasLogo => logoUrl != null && logoUrl!.trim().isNotEmpty;

  Map<String, dynamic> toMap({required String updatedBy}) {
    final trimmedAlias = alias?.trim() ?? '';
    return {
      'name': name.trim(),
      'address': address.trim(),
      if (logoUrl != null && logoUrl!.trim().isNotEmpty) 'logoUrl': logoUrl!.trim(),
      'alias': trimmedAlias.isEmpty ? FieldValue.delete() : trimmedAlias,
      if (hasCoordinates) ...{
        'latitude': latitude,
        'longitude': longitude,
      },
      'isBlocked': isBlocked,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  factory ChurchProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ChurchProfile(
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      alias: data['alias'] as String?,
      latitude: _readDouble(data['latitude']),
      longitude: _readDouble(data['longitude']),
      isBlocked: data['isBlocked'] as bool? ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return null;
  }
}
