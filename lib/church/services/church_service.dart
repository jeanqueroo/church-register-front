import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/church_profile.dart';
import '../../l10n/app_localizations.dart';
import '../models/church_record.dart';

class ChurchService {
  ChurchService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _churches = (firestore ?? FirebaseFirestore.instance)
            .collection('churches'),
        _storage = storage ?? _defaultStorage();

  /// Id legado cuando aún no hay multi-iglesia.
  static const String mainChurchId = 'main';

  final CollectionReference<Map<String, dynamic>> _churches;
  final FirebaseStorage _storage;

  static FirebaseStorage _defaultStorage() {
    final bucket = Firebase.app().options.storageBucket;
    if (bucket != null && bucket.isNotEmpty) {
      return FirebaseStorage.instanceFor(bucket: bucket);
    }
    return FirebaseStorage.instance;
  }

  String _resolveChurchId(String? churchId) =>
      churchId != null && churchId.isNotEmpty ? churchId : mainChurchId;

  DocumentReference<Map<String, dynamic>> _ref(String? churchId) =>
      _churches.doc(_resolveChurchId(churchId));

  Stream<List<ChurchRecord>> watchChurches() {
    return _churches.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => ChurchRecord(
              id: doc.id,
              profile: ChurchProfile.fromFirestore(doc),
            ),
          )
          .toList();
    });
  }

  Future<List<ChurchRecord>> fetchChurches() async {
    final snapshot = await _churches.orderBy('name').get();
    return snapshot.docs
        .map(
          (doc) => ChurchRecord(
            id: doc.id,
            profile: ChurchProfile.fromFirestore(doc),
          ),
        )
        .toList();
  }

  Stream<ChurchProfile?> watchChurch([String? churchId]) {
    return _ref(churchId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChurchProfile.fromFirestore(doc);
    });
  }

  Future<ChurchProfile?> fetchChurch([String? churchId]) async {
    final doc = await _ref(churchId).get();
    if (!doc.exists) return null;
    return ChurchProfile.fromFirestore(doc);
  }

  /// Crea una iglesia nueva y devuelve su id.
  Future<String> addChurch({
    required ChurchProfile profile,
    required String updatedBy,
  }) async {
    final doc = await _churches.add(profile.toMap(updatedBy: updatedBy));
    return doc.id;
  }

  Future<String> uploadLogo(
    Uint8List bytes, {
    required String churchId,
    String? contentType,
  }) async {
    final id = _resolveChurchId(churchId);
    final ref = _storage.ref().child('church_profiles/$id/logo.jpg');
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType ?? 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<void> saveChurch({
    required String churchId,
    required ChurchProfile profile,
    required String updatedBy,
  }) async {
    await _ref(churchId)
        .set(profile.toMap(updatedBy: updatedBy), SetOptions(merge: true));
  }

  Future<void> setChurchBlocked({
    required String churchId,
    required bool blocked,
    required String updatedBy,
  }) async {
    await _ref(churchId).update({
      'isBlocked': blocked,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    });
  }

  static bool _isStorageNotConfigured(FirebaseException e) {
    final message = (e.message ?? '').toLowerCase();
    return e.code == 'object-not-found' ||
        e.code == 'bucket-not-found' ||
        message.contains('404') ||
        message.contains('not found') ||
        message.contains('terminated the upload session');
  }

  static String messageFromException(Object e, AppLocalizations l10n) {
    if (e is FirebaseException) {
      if (_isStorageNotConfigured(e)) {
        return l10n.churchServiceStorageNotConfigured;
      }
      switch (e.code) {
        case 'permission-denied':
          return l10n.churchServicePermissionDenied;
        case 'not-found':
          return l10n.churchServiceNotFound;
        case 'unauthorized':
          return l10n.churchServiceUploadUnauthorized;
        case 'unavailable':
          return l10n.serviceUnavailable;
        default:
          return l10n.churchServiceSaveError(e.message ?? e.code);
      }
    }
    return l10n.serviceGenericError;
  }
}
