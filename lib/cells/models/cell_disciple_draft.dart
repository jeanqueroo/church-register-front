import '../../core/models/leader_gender.dart';
import '../../members/models/id_document_type.dart';
import 'cell_disciple.dart';

/// Datos de discípulo antes de persistir (p. ej. al crear la célula).
class CellDiscipleDraft {
  const CellDiscipleDraft({
    required this.lastName,
    required this.firstName,
    this.street,
    this.streetNumber,
    this.gender,
    this.idDocumentType,
    this.idDocumentNumber,
    this.birthDate,
    this.neighborhood,
    this.locality,
    this.stateProvince,
    this.postalCode,
    this.email,
    required this.latitude,
    required this.longitude,
    required this.mobilePhone,
    this.isBaptized = false,
    this.baptizedAt,
  });

  final String lastName;
  final String firstName;
  final String? street;
  final String? streetNumber;
  final LeaderGender? gender;
  final IdDocumentType? idDocumentType;
  final String? idDocumentNumber;
  final DateTime? birthDate;
  final String? neighborhood;
  final String? locality;
  final String? stateProvince;
  final String? postalCode;
  final String? email;
  final double latitude;
  final double longitude;
  final String mobilePhone;
  final bool isBaptized;
  final DateTime? baptizedAt;

  String get fullName =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();

  factory CellDiscipleDraft.fromDisciple(CellDisciple disciple) {
    return CellDiscipleDraft(
      lastName: disciple.lastName,
      firstName: disciple.firstName,
      street: disciple.street,
      streetNumber: disciple.streetNumber,
      gender: disciple.gender,
      idDocumentType: disciple.idDocumentType,
      idDocumentNumber: disciple.idDocumentNumber,
      birthDate: disciple.birthDate,
      neighborhood: disciple.neighborhood,
      locality: disciple.locality,
      stateProvince: disciple.stateProvince,
      postalCode: disciple.postalCode,
      email: disciple.email,
      latitude: disciple.latitude ?? 0,
      longitude: disciple.longitude ?? 0,
      mobilePhone: disciple.mobilePhone,
      isBaptized: disciple.isBaptized,
      baptizedAt: disciple.baptizedAt,
    );
  }

  CellDisciple toCellDisciple({
    required String cellId,
    required String cellCode,
    required String registeredBy,
    String? churchId,
  }) {
    return CellDisciple(
      cellId: cellId,
      lastName: lastName,
      firstName: firstName,
      street: street,
      streetNumber: streetNumber,
      cellCode: cellCode,
      gender: gender,
      idDocumentType: idDocumentType,
      idDocumentNumber: idDocumentNumber,
      birthDate: birthDate,
      neighborhood: neighborhood,
      locality: locality,
      stateProvince: stateProvince,
      postalCode: postalCode,
      email: email,
      latitude: latitude,
      longitude: longitude,
      mobilePhone: mobilePhone,
      registeredAt: DateTime.now(),
      registeredBy: registeredBy,
      churchId: churchId,
      isBaptized: isBaptized,
      baptizedAt: baptizedAt,
    );
  }
}
