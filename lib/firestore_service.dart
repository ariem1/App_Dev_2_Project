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
  String? _userId;

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
        final userDoc = _db.collection('users').doc(_user!.uid);
        final docSnapshot = await userDoc.get();

        // If the document doesn't exist, create it
        if (!docSnapshot.exists) {
          await userDoc.set({
            'name': 'Anonymous User _ Aura',
            'email': 'anonymous@example.com',
            'createdAt': Timestamp.now(),
            'journalName': '',
          });
          _userId = getCurrentUserId();
          print('Service: New user created: ${_userId}');
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

  ///// Get user id -- dont really need this/////
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


  // Method to check if a journal entry exists for today
  Future<bool> journalEntryExistsForToday() async {
    try {
   //   String? userId = getCurrentUserId();

      // Get the current date
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day); // Midnight of today
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999); // End of today

      // Query Firestore to check if an entry exists for today
      QuerySnapshot snapshot = await _db
          .collection('journals')
          .where('userId', isEqualTo: _userId)
          .where('entryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('entryDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // If documents are found, return true (entry exists)
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking journal entry for today: $e');
      return false;
    }
  }

  // Method to add a journal entry
  Future<void> addJournalEntry(int mood, String content, double expense) async {
    try {
      String? userId = getCurrentUserId();

      // Add a new journal entry
      await _db.collection('journals').add({
        'userId': userId,
        'entryDate': Timestamp.fromDate(DateTime.now()), // Store the current date
        'mood': mood,
        'content': content,
        'expense': expense,

      });
      print('Journal entry added successfully');
    } catch (e) {
      print('Error adding journal entry: $e');
    }
  }

  // Method to update a journal entry
  Future<void> updateJournalMood(String journalId, int mood) async {
    try {
      String? userId = getCurrentUserId();

      // Update the mood of the day's journal entry
      await _db.collection('journals').doc(journalId).update({
        'mood': mood,
      });
      print('Journal mood updated successfully');
    } catch (e) {
      print('Error updating journal entry mood: $e');
    }
  }

  // Method to fetch all journal entries for a user
  Future<List<Map<String, dynamic>>> getJournalEntries(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('journals')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> entries = [];
      snapshot.docs.forEach((doc) {
        entries.add(doc.data() as Map<String, dynamic>);
      });
      return entries;
    } catch (e) {
      print('Error fetching journal entries: $e');
      return [];
    }
  }

  // Returns the Journal Id for the day
  Future<String?> getJournalIdByUserIdAndDate() async {
    try {

      // Get the start and end of the day (midnight to 11:59 PM) for the query
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day); // Midnight of today
      DateTime endOfDay = startOfDay.add(Duration(days: 1)).subtract(Duration(seconds: 1));

      // Convert to Firestore's Timestamp
      Timestamp startTimestamp = Timestamp.fromDate(startOfDay);
      Timestamp endTimestamp = Timestamp.fromDate(endOfDay);

      // Query the Firestore collection
      QuerySnapshot snapshot = await _db.collection('journals')
          .where('userId', isEqualTo: _userId)
          .where('entryDate', isGreaterThanOrEqualTo: startTimestamp)
          .where('entryDate', isLessThanOrEqualTo: endTimestamp)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No journal entry found for this user on this date');
        return null; // No journal entry found for the given date
      }

      // Assuming only one journal entry for each user on a given day, return the first one
      return snapshot.docs.first.id;
    } catch (e) {
      print("Error fetching journal entry: $e");
      return null;
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


}
