import 'church_profile.dart';

/// Iglesia con id de documento en Firestore.
class ChurchRecord {
  const ChurchRecord({
    required this.id,
    required this.profile,
  });

  final String id;
  final ChurchProfile profile;

  String get name => profile.name;
  String get address => profile.address;
  bool get isBlocked => profile.isBlocked;
}
