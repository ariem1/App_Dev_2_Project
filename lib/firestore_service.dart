import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  // Singleton pattern for easy access
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  User? _user;

  /// Sign in anonymously and create user document and return the User object
  Future<User?> signInAnonymouslyAndCreateUser() async {
    try {
      // Sign in anonymously
      UserCredential userCredential = await _auth.signInAnonymously();
      _user = userCredential.user;
      print("Service: Signed in anonymously as: ${_user!.uid}");

      //Create user document in firestore
      // Check if user is not null
      if (_user != null) {
        // Create a Firestore document for the new user if it doesn't exist
        final userDoc = _db.collection('Users').doc(_user!.uid);
        final docSnapshot = await userDoc.get();

        // If the document doesn't exist, create it
        if (!docSnapshot.exists) {
          await userDoc.set({
            'name': 'Anonymous User _ Aura',
            'email': 'anonymous@example.com',
            'createdAt': Timestamp.now(),
            'journalName': '',
          });
          print('Service: New user created: ${_user!.uid}');
        } else {
          print('Service: User already exists: ${_user!.uid}');
        }
      }
      return _user;
    } catch (e) {
      print("Service:Error during anonymous sign-in and user creation: $e");
      return null;
    }
  }

  /// Sign out the currently authenticated user
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    print("User signed out");
  }

  /// Check if a user is currently signed in
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  ///// Get user id/////
  String? getCurrentUserId() {

      return _auth.currentUser?.uid;

  }

  //// Update journal name
  Future<void> updateJournalName(String newJournalName) async {
    try{
      String? currentUserId = getCurrentUserId();
      
      //update the user's journal name
      await _db.collection('Users').doc(currentUserId).update({
        'journalName' : newJournalName,
      });

      //print JournalName
      print('Journal name for ${_user?.uid} updated successfully to');
      DocumentSnapshot user_journalName = await _db.collection('Users').doc(_user?.uid).get();
      print(user_journalName);
    } catch (e){
      print('Journal name failed to update: $e');
    }
  }

 //////////// Add budget to collection


  /// Add or update a document in a collection
  Future<void> setData({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection(collection).doc(documentId).set(data);
      print("Document written to Firestore");
    } catch (e) {
      print("Error writing document: $e");
      rethrow;
    }
  }

  /// Get a single document by its ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      return await _db.collection(collection).doc(documentId).get();
    } catch (e) {
      print("Error getting document: $e");
      rethrow;
    }
  }

  /// Stream to get real-time updates from a collection
  Stream<List<Map<String, dynamic>>> getCollectionStream({
    required String collection,
  }) {
    return _db.collection(collection).snapshots().map(
            (snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Update a document in a collection
  Future<void> updateData({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection(collection).doc(documentId).update(data);
      print("Document updated");
    } catch (e) {
      print("Error updating document: $e");
      rethrow;
    }
  }

  /// Delete a document from a collection
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _db.collection(collection).doc(documentId).delete();
      print("Document deleted");
    } catch (e) {
      print("Error deleting document: $e");
      rethrow;
    }
  }
}
