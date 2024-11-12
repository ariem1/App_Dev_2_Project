import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance; //initialize and get a reference to your Firestore database.

  // Add Data
  Future<void> addUser(String userId, String name, int age) async {
    await _db.collection('users').doc(userId).set({
      'name': name,
      'age': age,
    });
  }

  // Fetch Data
  Stream<List<Map<String, dynamic>>> getUsers() {
    return _db.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  // Update Data
  Future<void> updateUser(String userId, String newName) async {
    await _db.collection('users').doc(userId).update({'name': newName});
  }

  // Delete Data
  Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).delete();
  }
}
