import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';
import 'id_document_type.dart';
import 'marital_status.dart';
import 'member_entry_source.dart';

class ChurchMember {
  const ChurchMember({
    this.id,
    required this.firstName,
    required this.lastName,
    this.gender,
    this.street,
    this.streetNumber,
    this.neighborhood,
    this.locality,
    this.stateProvince,
    this.postalCode,
    this.latitude,
    this.longitude,
    required this.phone,
    this.idDocumentType,
    this.idDocumentNumber,
    this.birthDate,
    this.occupation,
    this.maritalStatus,
    this.cellDay,
    this.cellTime,
    this.cellZone,
    this.observations,
    this.volunteer,
    this.assignedLeaderId,
    this.assignedLeaderName,
    this.assignedLeaderCellCode,
    this.assignedDistanceKm,
    this.wantsVisit = true,
    this.isNewBeliever = false,
    this.entrySource,
    required this.formDate,
    required this.registeredAt,
    required this.registeredBy,
    this.churchId,
  });

  final String? id;
  final String firstName;
  final String lastName;
  final LeaderGender? gender;
  final String? street;
  final String? streetNumber;
  final String? neighborhood;
  final String? locality;
  final String? stateProvince;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final String phone;
  final IdDocumentType? idDocumentType;
  final String? idDocumentNumber;
  final DateTime? birthDate;
  final String? occupation;
  final MaritalStatus? maritalStatus;
  final String? cellDay;
  final String? cellTime;
  final String? cellZone;
  final String? observations;
  final String? volunteer;
  final String? assignedLeaderId;
  final String? assignedLeaderName;
  final String? assignedLeaderCellCode;
  final double? assignedDistanceKm;
  final bool wantsVisit;
  /// `true` al registrar por primera vez; se conserva en ediciones posteriores.
  final bool isNewBeliever;
  final MemberEntrySource? entrySource;
  final DateTime formDate;
  final DateTime registeredAt;
  final String registeredBy;
  final String? churchId;

  String get fullName =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();

  /// Edad en años completos según la fecha de nacimiento.
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
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender?.code,
      'street': street,
      'streetNumber': streetNumber,
      'neighborhood': neighborhood,
      'locality': locality,
      'stateProvince': stateProvince,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'idDocumentType': idDocumentType?.name,
      'idDocumentNumber': idDocumentNumber,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'occupation': occupation,
      'maritalStatus': maritalStatus?.name,
      'cellDay': cellDay,
      'cellTime': cellTime,
      'cellZone': cellZone,
      'observations': observations,
      'volunteer': volunteer,
      'assignedLeaderId': assignedLeaderId,
      'assignedLeaderName': assignedLeaderName,
      'assignedLeaderCellCode': assignedLeaderCellCode,
      'assignedDistanceKm': assignedDistanceKm,
      'wantsVisit': wantsVisit,
      'isNewBeliever': isNewBeliever,
      'entrySource': entrySource?.name,
      'formDate': Timestamp.fromDate(formDate),
      'registeredAt': Timestamp.fromDate(registeredAt),
      'registeredBy': registeredBy,
      if (churchId != null && churchId!.isNotEmpty) 'churchId': churchId,
    };
  }

  factory ChurchMember.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    String firstName;
    String lastName;

    if (data['firstName'] != null) {
      firstName = data['firstName'] as String;
      lastName = data['lastName'] as String? ?? '';
    } else {
      final legacyName = data['fullName'] as String? ?? '';
      final parts = legacyName.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty || parts.first.isEmpty) {
        firstName = 'Sin nombre';
        lastName = '';
      } else {
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }

    final legacyAddress = data['address'] as String?;

    return ChurchMember(
      id: doc.id,
      firstName: firstName,
      lastName: lastName,
      gender: LeaderGender.fromCode(data['gender'] as String?),
      street: data['street'] as String? ?? legacyAddress,
      streetNumber: data['streetNumber'] as String?,
      neighborhood: data['neighborhood'] as String?,
      locality: data['locality'] as String?,
      stateProvince: data['stateProvince'] as String?,
      postalCode: data['postalCode'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      phone: data['phone'] as String? ?? '',
      idDocumentType:
          IdDocumentType.fromString(data['idDocumentType'] as String?),
      idDocumentNumber: data['idDocumentNumber'] as String?,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      occupation: data['occupation'] as String?,
      maritalStatus: MaritalStatus.fromString(data['maritalStatus'] as String?),
      cellDay: data['cellDay'] as String?,
      cellTime: data['cellTime'] as String?,
      cellZone: data['cellZone'] as String?,
      observations: data['observations'] as String?,
      volunteer: data['volunteer'] as String?,
      assignedLeaderId: data['assignedLeaderId'] as String?,
      assignedLeaderName: data['assignedLeaderName'] as String?,
      assignedLeaderCellCode: data['assignedLeaderCellCode'] as String?,
      assignedDistanceKm: (data['assignedDistanceKm'] as num?)?.toDouble(),
      wantsVisit: data['wantsVisit'] as bool? ?? true,
      isNewBeliever: data['isNewBeliever'] as bool? ?? false,
      entrySource:
          MemberEntrySource.fromString(data['entrySource'] as String?),
      formDate: (data['formDate'] as Timestamp?)?.toDate() ??
          (data['registeredAt'] as Timestamp).toDate(),
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      registeredBy: data['registeredBy'] as String? ?? '',
      churchId: data['churchId'] as String?,
    );
  }
}
