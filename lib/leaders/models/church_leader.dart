import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';
import '../../core/search/firestore_search_text.dart';
import '../../l10n/app_localizations.dart';
import '../../members/models/id_document_type.dart';
import 'church_office.dart';
import 'leader_registration_source.dart';

class ChurchLeader {
  const ChurchLeader({
    this.id,
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
    this.authUserId,
    this.latitude,
    this.longitude,
    required this.mobilePhone,
    required this.registeredAt,
    required this.registeredBy,
    this.churchId,
    this.registrationSource,
    this.churchOffice,
    this.appRoles,
    this.photoUrl,
    this.isBlocked = false,
  });

  final String? id;
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
  final String? authUserId;
  final double? latitude;
  final double? longitude;
  final String mobilePhone;
  final DateTime registeredAt;
  final String registeredBy;
  final String? churchId;
  final LeaderRegistrationSource? registrationSource;
  final ChurchOffice? churchOffice;
  /// Roles de app en `users` (p. ej. leader, supervisor, registrador).
  final List<String>? appRoles;
  final String? photoUrl;
  final bool isBlocked;

  String get fullName =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();

  String? registrationSourceLabel(AppLocalizations l10n) =>
      registrationSource?.localizedLabel(l10n);

  /// Índice en minúsculas para búsqueda (nombre + apellido).
  String buildSearchIndex() {
    return joinSearchParts([
      fullName,
      firstName,
      lastName,
      cellCode,
      mobilePhone,
      email,
      churchOffice?.code,
      churchOffice?.label,
      locality,
      neighborhood,
      idDocumentNumber,
    ]);
  }

  /// Índice alterno (apellido primero).
  String buildSearchLastFirstIndex() {
    return joinSearchParts([
      lastName,
      firstName,
      fullName,
      cellCode,
      mobilePhone,
      email,
      churchOffice?.code,
      churchOffice?.label,
      locality,
      neighborhood,
      idDocumentNumber,
    ]);
  }

  /// Coincide con la consulta (contiene todas las palabras).
  bool matchesSearchQuery(String query) {
    final normalizedQuery = normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return true;

    final haystack = '${buildSearchIndex()} ${buildSearchLastFirstIndex()}';
    final terms = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    return terms.every(haystack.contains);
  }

  /// El líder pertenece a la iglesia indicada (mismo `churchId` en Firestore).
  bool belongsToChurch(String? targetChurchId) {
    final normalizedTarget = targetChurchId?.trim();
    if (normalizedTarget == null || normalizedTarget.isEmpty) return false;
    final normalizedLeader = churchId?.trim();
    return normalizedLeader != null &&
        normalizedLeader.isNotEmpty &&
        normalizedLeader == normalizedTarget;
  }

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

  Map<String, dynamic> toMap() {
    return {
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
      'authUserId': authUserId,
      'latitude': latitude,
      'longitude': longitude,
      'mobilePhone': mobilePhone,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'registeredBy': registeredBy,
      'searchName': buildSearchIndex(),
      'searchLastFirst': buildSearchLastFirstIndex(),
      if (churchId != null && churchId!.isNotEmpty) 'churchId': churchId,
      if (registrationSource != null)
        'registrationSource': registrationSource!.storageKey,
      if (churchOffice != null) 'churchOffice': churchOffice!.code,
      if (appRoles != null && appRoles!.isNotEmpty) 'appRoles': appRoles,
      if (photoUrl != null && photoUrl!.trim().isNotEmpty)
        'photoUrl': photoUrl!.trim(),
      'isBlocked': isBlocked,
    };
  }

  factory ChurchLeader.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ChurchLeader(
      id: doc.id,
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
      authUserId: data['authUserId'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      mobilePhone: data['mobilePhone'] as String? ?? '',
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      registeredBy: data['registeredBy'] as String? ?? '',
      churchId: data['churchId'] as String?,
      registrationSource: LeaderRegistrationSource.fromString(
        data['registrationSource'] as String?,
      ),
      churchOffice: ChurchOffice.fromCode(data['churchOffice'] as String?),
      appRoles: (data['appRoles'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      photoUrl: data['photoUrl'] as String?,
      isBlocked: data['isBlocked'] as bool? ?? false,
    );
  }
}
