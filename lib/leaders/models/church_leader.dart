import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';

class ChurchLeader {
  const ChurchLeader({
    this.id,
    required this.lastName,
    required this.firstName,
    this.street,
    this.streetNumber,
    this.cellCode,
    this.gender,
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
  });

  final String? id;
  final String lastName;
  final String firstName;
  final String? street;
  final String? streetNumber;
  final String? cellCode;
  final LeaderGender? gender;
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

  String get fullName =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();

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
      'lastName': lastName,
      'firstName': firstName,
      'street': street,
      'streetNumber': streetNumber,
      'cellCode': cellCode,
      'gender': gender?.code,
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
    );
  }
}
