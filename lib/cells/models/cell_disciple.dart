import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';
import '../../leaders/models/church_office.dart';
import '../../members/models/id_document_type.dart';

/// Discípulo registrado en una célula (`cells/{cellId}/disciples`).
class CellDisciple {
  const CellDisciple({
    this.id,
    required this.cellId,
    required this.lastName,
    required this.firstName,
    this.street,
    this.streetNumber,
    this.cellCode,
    this.gender,
    this.idDocumentType,
    this.idDocumentNumber,
    this.birthDate,
    this.neighborhood,
    this.locality,
    this.stateProvince,
    this.postalCode,
    this.email,
    this.latitude,
    this.longitude,
    required this.mobilePhone,
    required this.registeredAt,
    required this.registeredBy,
    this.churchId,
    this.churchOffice,
    this.isBaptized = false,
    this.baptizedAt,
  });

  final String? id;
  final String cellId;
  final String lastName;
  final String firstName;
  final String? street;
  final String? streetNumber;
  final String? cellCode;
  final LeaderGender? gender;
  final IdDocumentType? idDocumentType;
  final String? idDocumentNumber;
  final DateTime? birthDate;
  final String? neighborhood;
  final String? locality;
  final String? stateProvince;
  final String? postalCode;
  final String? email;
  final double? latitude;
  final double? longitude;
  final String mobilePhone;
  final DateTime registeredAt;
  final String registeredBy;
  final String? churchId;
  final ChurchOffice? churchOffice;
  final bool isBaptized;
  final DateTime? baptizedAt;

  String get fullName =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();

  GeoLocation? get geoLocation {
    if (latitude == null || longitude == null) return null;
    return GeoLocation(latitude: latitude!, longitude: longitude!);
  }

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var years = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }
    return years;
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

  bool get isAssignedToCell => cellId.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'cellId': cellId,
      'lastName': lastName,
      'firstName': firstName,
      'street': street,
      'streetNumber': streetNumber,
      'cellCode': cellCode,
      'gender': gender?.code,
      'idDocumentType': idDocumentType?.name,
      'idDocumentNumber': idDocumentNumber,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'neighborhood': neighborhood,
      'locality': locality,
      'stateProvince': stateProvince,
      'postalCode': postalCode,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'mobilePhone': mobilePhone,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'registeredBy': registeredBy,
      if (churchId != null && churchId!.isNotEmpty) 'churchId': churchId,
      if (churchOffice != null) 'churchOffice': churchOffice!.code,
      'isBaptized': isBaptized,
      if (baptizedAt != null) 'baptizedAt': Timestamp.fromDate(baptizedAt!),
    };
  }

  /// Mapa para la colección raíz `disciples` (sin célula asignada).
  Map<String, dynamic> toUnassignedMap() {
    return {
      ...toMap(),
      'cellId': '',
      'cellCode': null,
      'assigned': false,
    };
  }

  factory CellDisciple.fromRootFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CellDisciple(
      id: doc.id,
      cellId: data['cellId'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      street: data['street'] as String?,
      streetNumber: data['streetNumber'] as String?,
      cellCode: data['cellCode'] as String?,
      gender: LeaderGender.fromCode(data['gender'] as String?),
      idDocumentType:
          IdDocumentType.fromString(data['idDocumentType'] as String?),
      idDocumentNumber: data['idDocumentNumber'] as String?,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      neighborhood: data['neighborhood'] as String?,
      locality: data['locality'] as String?,
      stateProvince: data['stateProvince'] as String?,
      postalCode: data['postalCode'] as String?,
      email: data['email'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      mobilePhone: data['mobilePhone'] as String? ?? '',
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      registeredBy: data['registeredBy'] as String? ?? '',
      churchId: data['churchId'] as String?,
      churchOffice: ChurchOffice.fromCode(data['churchOffice'] as String?),
      isBaptized: data['isBaptized'] as bool? ?? false,
      baptizedAt: (data['baptizedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory CellDisciple.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String cellId,
  }) {
    final data = doc.data()!;
    return CellDisciple(
      id: doc.id,
      cellId: cellId,
      lastName: data['lastName'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      street: data['street'] as String?,
      streetNumber: data['streetNumber'] as String?,
      cellCode: data['cellCode'] as String?,
      gender: LeaderGender.fromCode(data['gender'] as String?),
      idDocumentType:
          IdDocumentType.fromString(data['idDocumentType'] as String?),
      idDocumentNumber: data['idDocumentNumber'] as String?,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      neighborhood: data['neighborhood'] as String?,
      locality: data['locality'] as String?,
      stateProvince: data['stateProvince'] as String?,
      postalCode: data['postalCode'] as String?,
      email: data['email'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      mobilePhone: data['mobilePhone'] as String? ?? '',
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      registeredBy: data['registeredBy'] as String? ?? '',
      churchId: data['churchId'] as String?,
      churchOffice: ChurchOffice.fromCode(data['churchOffice'] as String?),
      isBaptized: data['isBaptized'] as bool? ?? false,
      baptizedAt: (data['baptizedAt'] as Timestamp?)?.toDate(),
    );
  }
}
