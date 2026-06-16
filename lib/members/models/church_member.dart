import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';
import '../../core/search/firestore_search_text.dart';
import '../../core/utils/birthday_date.dart';
import '../../l10n/app_localizations.dart';
import 'id_document_type.dart';
import 'marital_status.dart';
import 'member_assignment_kind.dart';
import 'member_entry_source.dart';
import 'member_leadership_status.dart';
import 'spiritual_state.dart';

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
    this.assignedLeaderFromRegistration,
    this.assignmentKind,
    this.assignedCellId,
    this.assignedCellCode,
    this.spiritualState,
    this.assignedDistanceKm,
    this.wantsVisit = true,
    this.isNewBeliever = false,
    this.isBaptized = false,
    this.baptizedAt,
    this.entrySource,
    this.entrySourceStored,
    required this.formDate,
    required this.registeredAt,
    required this.registeredBy,
    this.churchId,
    this.leadershipStatus,
    this.linkedLeaderId,
    this.promotedToLeaderAt,
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
  /// `true` si el líder se asignó en el registro/edición pastoral (no por célula).
  final bool? assignedLeaderFromRegistration;
  /// Distingue asignación pastoral vs integrante de célula.
  final MemberAssignmentKind? assignmentKind;
  final String? assignedCellId;
  final String? assignedCellCode;
  final SpiritualState? spiritualState;
  final double? assignedDistanceKm;
  final bool wantsVisit;
  /// `true` al registrar por primera vez; se conserva en ediciones posteriores.
  final bool isNewBeliever;
  /// `true` si el integrante ya fue bautizado.
  final bool isBaptized;
  final DateTime? baptizedAt;
  final MemberEntrySource? entrySource;
  final String? entrySourceStored;
  final DateTime formDate;

  String? entrySourceLabel(AppLocalizations l10n) =>
      MemberEntrySource.storedValueLabel(
        entrySource?.name ?? entrySourceStored,
        l10n,
      );
  final DateTime registeredAt;
  final String registeredBy;
  final String? churchId;
  /// Estado cuando el integrante pasa a ser líder (p. ej. al dividir célula).
  final MemberLeadershipStatus? leadershipStatus;
  /// Id del documento en `leaders` vinculado a este integrante.
  final String? linkedLeaderId;
  final DateTime? promotedToLeaderAt;

  bool get hasBeenPromotedToLeader =>
      leadershipStatus == MemberLeadershipStatus.promotedToLeader;

  bool get hasBeenPromotedToVolunteer =>
      leadershipStatus == MemberLeadershipStatus.promotedToVolunteer;

  bool get wasCreatedAsLeader =>
      leadershipStatus == MemberLeadershipStatus.createdAsLeader;

  bool get hasPromotedLeadershipStatus =>
      hasBeenPromotedToLeader ||
      hasBeenPromotedToVolunteer ||
      wasCreatedAsLeader;

  /// Líderes y supervisores no pueden ser discípulos de célula; los registradores sí.
  bool get canBeAssignedAsCellDisciple =>
      !wasCreatedAsLeader && !hasBeenPromotedToLeader;

  bool get canBeAssignedToBaptism => !isBaptized;

  String? leadershipStatusLabel(AppLocalizations l10n) =>
      leadershipStatus?.localizedLabel(l10n);

  String get fullName =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();

  /// Índice en minúsculas para búsqueda por prefijo (nombre + apellido).
  String buildSearchIndex() {
    return joinSearchParts([
      fullName,
      firstName,
      lastName,
      phone,
      assignedLeaderName,
      assignedLeaderCellCode,
      assignedCellCode,
      locality,
      neighborhood,
      cellZone,
      occupation,
      volunteer,
      maritalStatus?.label,
      entrySource?.name ?? entrySourceStored,
      gender?.label,
      idDocumentNumber,
    ]);
  }

  /// Índice alterno (apellido primero) para búsqueda por apellido.
  String buildSearchLastFirstIndex() {
    return joinSearchParts([
      lastName,
      firstName,
      fullName,
      phone,
      assignedLeaderName,
      assignedLeaderCellCode,
      assignedCellCode,
      locality,
      neighborhood,
      cellZone,
      occupation,
      volunteer,
      maritalStatus?.label,
      entrySource?.name ?? entrySourceStored,
      gender?.label,
      idDocumentNumber,
    ]);
  }

  /// Coincide con la consulta (contiene todas las palabras, sin depender de Firestore).
  bool matchesSearchQuery(String query) {
    final normalizedQuery = normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return true;

    final haystack = '${buildSearchIndex()} ${buildSearchLastFirstIndex()}';
    final terms = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    return terms.every(haystack.contains);
  }

  bool get isAssignedToCell =>
      assignedCellId != null && assignedCellId!.trim().isNotEmpty;

  /// Integrante con líder pastoral asignado en el flujo de registro (no célula).
  bool get isPastoralLeaderAssignment {
    if (assignmentKind == MemberAssignmentKind.pastoral) return true;
    if (assignmentKind == MemberAssignmentKind.cell) return false;

    final leaderId = assignedLeaderId?.trim();
    if (leaderId == null || leaderId.isEmpty) return false;
    if (assignedLeaderFromRegistration == true) return true;
    if (assignedLeaderFromRegistration == false) return false;
    // Datos anteriores al campo: sin célula se asume registro pastoral.
    return !isAssignedToCell;
  }

  /// Integrante asignado a una célula (discípulo de célula).
  bool get isCellMemberAssignment {
    if (assignmentKind == MemberAssignmentKind.cell) return true;
    if (assignmentKind == MemberAssignmentKind.pastoral) return false;
    return isAssignedToCell;
  }

  String? assignmentKindLabel(AppLocalizations l10n) =>
      assignmentKind?.label(l10n);

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
      'birthDate': birthDate != null
          ? Timestamp.fromDate(BirthdayDate.normalize(birthDate)!)
          : null,
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
      if (assignedLeaderFromRegistration != null)
        'assignedLeaderFromRegistration': assignedLeaderFromRegistration,
      if (assignmentKind != null) 'assignmentKind': assignmentKind!.storageKey,
      if (assignedCellId != null && assignedCellId!.isNotEmpty)
        'assignedCellId': assignedCellId,
      if (assignedCellCode != null && assignedCellCode!.isNotEmpty)
        'assignedCellCode': assignedCellCode,
      if (spiritualState != null) 'spiritualState': spiritualState!.name,
      'assignedDistanceKm': assignedDistanceKm,
      'wantsVisit': wantsVisit,
      'isNewBeliever': isNewBeliever,
      'isBaptized': isBaptized,
      if (baptizedAt != null) 'baptizedAt': Timestamp.fromDate(baptizedAt!),
      'entrySource': entrySource?.name,
      'formDate': Timestamp.fromDate(formDate),
      'registeredAt': Timestamp.fromDate(registeredAt),
      'registeredBy': registeredBy,
      'searchName': buildSearchIndex(),
      'searchLastFirst': buildSearchLastFirstIndex(),
      if (churchId != null && churchId!.isNotEmpty) 'churchId': churchId,
      if (leadershipStatus != null)
        'leadershipStatus': leadershipStatus!.name,
      if (linkedLeaderId != null && linkedLeaderId!.isNotEmpty)
        'linkedLeaderId': linkedLeaderId,
      if (promotedToLeaderAt != null)
        'promotedToLeaderAt': Timestamp.fromDate(promotedToLeaderAt!),
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
      birthDate: BirthdayDate.normalize(
        (data['birthDate'] as Timestamp?)?.toDate(),
      ),
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
      assignedLeaderFromRegistration:
          data['assignedLeaderFromRegistration'] as bool?,
      assignmentKind:
          MemberAssignmentKind.fromString(data['assignmentKind'] as String?),
      assignedCellId: data['assignedCellId'] as String?,
      assignedCellCode: data['assignedCellCode'] as String?,
      spiritualState:
          SpiritualState.fromString(data['spiritualState'] as String?),
      assignedDistanceKm: (data['assignedDistanceKm'] as num?)?.toDouble(),
      wantsVisit: data['wantsVisit'] as bool? ?? true,
      isNewBeliever: data['isNewBeliever'] as bool? ?? false,
      isBaptized: data['isBaptized'] as bool? ?? false,
      baptizedAt: (data['baptizedAt'] as Timestamp?)?.toDate(),
      entrySource:
          MemberEntrySource.fromString(data['entrySource'] as String?),
      entrySourceStored: data['entrySource'] as String?,
      formDate: (data['formDate'] as Timestamp?)?.toDate() ??
          (data['registeredAt'] as Timestamp).toDate(),
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      registeredBy: data['registeredBy'] as String? ?? '',
      churchId: data['churchId'] as String?,
      leadershipStatus: MemberLeadershipStatus.fromString(
        data['leadershipStatus'] as String?,
      ),
      linkedLeaderId: data['linkedLeaderId'] as String?,
      promotedToLeaderAt:
          (data['promotedToLeaderAt'] as Timestamp?)?.toDate(),
    );
  }
}
