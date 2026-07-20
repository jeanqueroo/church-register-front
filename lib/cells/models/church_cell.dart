import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/geo_location.dart';
import 'cell_helper.dart';

/// Grupo celular registrado en la iglesia (colección `cells`).
class ChurchCell {
  const ChurchCell({
    this.id,
    required this.code,
    this.name,
    this.street,
    this.streetNumber,
    this.neighborhood,
    this.locality,
    this.stateProvince,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.cellDay,
    this.leaderId,
    this.leaderName,
    this.notes,
    this.alias,
    this.helpers = const [],
    required this.registeredAt,
    required this.registeredBy,
    this.churchId,
    this.memberCount,
  });

  static const maxHelpers = 3;

  final String? id;
  final String code;
  final String? name;
  final String? street;
  final String? streetNumber;
  final String? neighborhood;
  final String? locality;
  final String? stateProvince;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final String? cellDay;
  final String? leaderId;
  final String? leaderName;
  final String? notes;
  /// Alias bancario para transferencias.
  final String? alias;
  final List<CellHelper> helpers;
  final DateTime registeredAt;
  final String registeredBy;
  final String? churchId;
  final int? memberCount;

  String get displayLabel {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      return '$code · $trimmedName';
    }
    return code;
  }

  GeoLocation? get geoLocation {
    if (latitude == null || longitude == null) return null;
    return GeoLocation(latitude: latitude!, longitude: longitude!);
  }

  String get formattedAddress {
    return [
      street,
      streetNumber,
      neighborhood,
      locality,
      stateProvince,
      postalCode,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code.trim(),
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      if (street != null && street!.trim().isNotEmpty) 'street': street!.trim(),
      if (streetNumber != null && streetNumber!.trim().isNotEmpty)
        'streetNumber': streetNumber!.trim(),
      if (neighborhood != null && neighborhood!.trim().isNotEmpty)
        'neighborhood': neighborhood!.trim(),
      if (locality != null && locality!.trim().isNotEmpty)
        'locality': locality!.trim(),
      if (stateProvince != null && stateProvince!.trim().isNotEmpty)
        'stateProvince': stateProvince!.trim(),
      if (postalCode != null && postalCode!.trim().isNotEmpty)
        'postalCode': postalCode!.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (cellDay != null && cellDay!.trim().isNotEmpty) 'cellDay': cellDay!.trim(),
      if (leaderId != null && leaderId!.isNotEmpty) 'leaderId': leaderId,
      if (leaderName != null && leaderName!.trim().isNotEmpty)
        'leaderName': leaderName!.trim(),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      if (alias != null && alias!.trim().isNotEmpty) 'alias': alias!.trim(),
      'helpers': helpers.map((helper) => helper.toMap()).toList(),
      'registeredAt': Timestamp.fromDate(registeredAt),
      'registeredBy': registeredBy,
      if (churchId != null && churchId!.isNotEmpty) 'churchId': churchId,
      if (memberCount != null) 'memberCount': memberCount,
    };
  }

  factory ChurchCell.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ChurchCell(
      id: doc.id,
      code: data['code'] as String? ?? '',
      name: data['name'] as String?,
      street: data['street'] as String?,
      streetNumber: data['streetNumber'] as String?,
      neighborhood: data['neighborhood'] as String?,
      locality: data['locality'] as String?,
      stateProvince: data['stateProvince'] as String?,
      postalCode: data['postalCode'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      cellDay: data['cellDay'] as String?,
      leaderId: data['leaderId'] as String?,
      leaderName: data['leaderName'] as String?,
      notes: data['notes'] as String?,
      alias: data['alias'] as String?,
      helpers: CellHelper.listFromFirestore(data['helpers']),
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      registeredBy: data['registeredBy'] as String? ?? '',
      churchId: data['churchId'] as String?,
      memberCount: (data['memberCount'] as num?)?.toInt(),
    );
  }
}
