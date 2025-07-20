import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/password_entry.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'passwords';

  // Save password entry
  Future<String> savePassword(PasswordEntry entry) async {
    try {
      DocumentReference docRef =
          await _firestore.collection(_collection).add(entry.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save password: $e');
    }
  }

  // Get all password entries
  Future<List<PasswordEntry>> getPasswords() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();

      return snapshot.docs
          .map((doc) => PasswordEntry.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch passwords: $e');
    }
  }

  // Update password entry
  Future<void> updatePassword(PasswordEntry entry) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(entry.id)
          .update(entry.toJson());
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  // Delete password entry
  Future<void> deletePassword(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete password: $e');
    }
  }

  // Real-time stream of passwords
  Stream<List<PasswordEntry>> getPasswordsStream() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PasswordEntry.fromJson(
                  doc.data() as Map<String, dynamic>,
                  id: doc.id,
                ))
            .toList());
  }
}
