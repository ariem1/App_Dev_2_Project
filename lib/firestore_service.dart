import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  //// Update journal name
  Future<void> updateJournalName(String newJournalName) async {
    try {
      String? currentUserId = getCurrentUserId();
      print('Journal name for ${currentUserId} is being updated');

      //update the user's journal name
      await _db.collection('users').doc(currentUserId).update({
        'journalName': newJournalName,
      });

      //print JournalName
      print('Journal name for ${currentUserId} updated successfully to');
      DocumentSnapshot user_journalName =
          await _db.collection('users').doc(currentUserId).get();
      print(user_journalName);
    } catch (e) {
      print('Journal name failed to update: $e $newJournalName');
    }
  }

  // Method to check if a journal entry exists for today
  Future<bool> journalEntryExistsForToday() async {
    try {
      //   String? userId = getCurrentUserId();

      // Get the current date
      DateTime now = DateTime.now();
      DateTime startOfDay =
          DateTime(now.year, now.month, now.day); // Midnight of today
      DateTime endOfDay = DateTime(
          now.year, now.month, now.day, 23, 59, 59, 999); // End of today

      // Query Firestore to check if an entry exists for today
      QuerySnapshot snapshot = await _db
          .collection('journals')
          .where('userId', isEqualTo: _userId)
          .where('entryDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('entryDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // If documents are found, return true (entry exists)
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking journal entry for today: $e');
      return false;
    }
  }

  // Method to add a journal
  Future<void> addJournalEntry(
      int water,
      int mood,
    String content,
  ) async {
    try {
      String? userId = getCurrentUserId();

      // Add a new journal entry
      DocumentReference journal = await _db.collection('journals').add({
        'userId': userId,
        'entryDate':
            Timestamp.fromDate(DateTime.now()), // Store the current date
        'mood': mood,
        'content': content,
        'budget': null, //null for now
        'title': '',
        'description': '',
        'water': water,
        'imagePath': ''

      });
      print('Journal entry added successfully');

      //get id of journal just made
      String journalId = journal.id;

      //create budget entry
      String budgetId = await createBudgetEntry(journalId);

      //update the journal entry's budget field to be the one we created
      await _db
          .collection('journals')
          .doc(journalId)
          .update({'budget': budgetId});
    } catch (e) {
      print('Error adding journal entry: $e');
    }
  }

  // Update a journal - entry
  Future<void> updateJournalEntry(String entry, String desc, String title) async {
    try {
      String? userId = getCurrentUserId();

      String? journalId = await getJournalIdByUserIdAndDate();

      // Update the mood of the day's journal entry
      await _db.collection('journals').doc(journalId).update({
        'content': entry,
        'description': desc,
        'title': title,

      });
      print('Journal entry / content updated successfully');
    } catch (e) {
      print('Error updating journal entry / content: $e');
    }
  }

  //Fetches the data of a journal
  Future<Map<String, dynamic>> fetchJournalData() async {
    try {
      String? userId = getCurrentUserId();
      String? journalId = await getJournalIdByUserIdAndDate();

      if (journalId == null) {
        print('No journal found for the user today.');
        return {}; // Return an empty map if no journal is found
      }

      print('Fetching journal entry for ID: $journalId');
      var snapshot = await FirebaseFirestore.instance
          .collection('journals')
          .doc(journalId)
          .get();

      if (!snapshot.exists) {
        print('No journal found for today');
        return {};
      }

      // Return all relevant fields in a map
      return {
        'title': snapshot.get('title') ?? '',
        'description': snapshot.get('description') ?? '',
        'content': snapshot.get('content') ?? '',
        'mood': snapshot.get('mood') ?? '',
        'entryDate': snapshot.get('entryDate') ?? '',
        'water': snapshot.get('water') ?? 0,
        'imagePath':  snapshot.get('imagePath') ?? '',



      };
    } catch (e) {
      print('Error fetching journal entry: $e');
      return {};
    }
  }

  //Fetches the data of a journal
  Future<Map<String, dynamic>> fetchJournalDataByDateAndUser(
      DateTime selectedDate) async {
    // Get start and end of the target day
    DateTime startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));
    String? userId = getCurrentUserId();

    print('Journal: for $userId');


    try {
      // Query Firestore for a journal entry with the userId and within the date range
      var querySnapshot = await FirebaseFirestore.instance
          .collection('journals')
          .where('userId', isEqualTo: userId) // Filter by userId
          .where('entryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay)) // Start of day
          .where('entryDate', isLessThan: Timestamp.fromDate(endOfDay)) // End of day
          .get();

      // Check if any documents match the query
      if (querySnapshot.docs.isEmpty) {
        print('No journal entry found for the provided user and date.');
        return {};
      }

      // Assuming only one journal entry per user per day, fetch the first result
      var document = querySnapshot.docs.first;

      // Return all relevant fields in a map
      return {
        'title': document.get('title') ?? '',
        'description': document.get('description') ?? '',
        'content': document.get('content') ?? '',
        'mood': document.get('mood') ?? '',
        'entryDate': document.get('entryDate') ?? '',
        'water': document.get('water') ?? 0,
        'imagePath':  document.get('imagePath') ?? '',

      };
    } catch (e) {
      print('Journal: Errorr fetching journal entry: $e for $userId');
      return {};
    }
  }


  // Update a journal - mood
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

  // Update a journal - mood
  Future<void> updateJournalWater(String journalId, int water) async {
    try {

      // Update the mood of the day's journal entry
      await _db.collection('journals').doc(journalId).update({
        'water': water,
      });
      print('Journal water updated successfully');
    } catch (e) {
      print('Error updating journal entry water: $e');
    }
  }

  // Method to fetch all journal entries for a user
  Future<List<Map<String, dynamic>>> getAllJournalEntries() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('journals')
          .where('userId', isEqualTo: _userId)
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
      DateTime startOfDay =
          DateTime(now.year, now.month, now.day); // Midnight of today
      DateTime endOfDay =
          startOfDay.add(Duration(days: 1)).subtract(Duration(seconds: 1));

      // Convert to Firestore's Timestamp
      Timestamp startTimestamp = Timestamp.fromDate(startOfDay);
      Timestamp endTimestamp = Timestamp.fromDate(endOfDay);

      // Query the Firestore collection
      QuerySnapshot snapshot = await _db
          .collection('journals')
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

  // mood from a specific journal entry by its ID
  Future<int?> getJournalMood(String journalId) async {
    try {
      DocumentSnapshot journalDoc =
          await _db.collection('journals').doc(journalId).get();

      // Check if the journal entry exists
      if (journalDoc.exists) {
        return journalDoc['mood'] as int?;
      } else {
        print('Journal entry not found for the given ID');
        return null; // Journal entry not found
      }
    } catch (e) {
      print('Error fetching journal mood: $e');
      return null;
    }
  }

  //Upload image to Firebase
  Future<String?> uploadImageToFirebase(File image) async {
    try {
      print('step 3');

      // Create a unique file name for the image
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      print('Imageee uploaded successfully. Path: images/$fileName');

      // Reference to the Firebase Storage location
     Reference storageRef = FirebaseStorage.instance.ref().child('images/$fileName');



      // Upload the image file
  UploadTask uploadTask = storageRef.putFile(image);

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get the image's download URL
      String downloadURL = await snapshot.ref.getDownloadURL();

      if (downloadURL != ""){
        print('Download URL: $downloadURL');

      } else{
        print('booty');
      }
      print('Image uploaded successfully. Path: images/$fileName');
      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> saveImageURLToFirestore(String imageURL) async {
    try {
      await FirebaseFirestore.instance.collection('images').add({
        'url': imageURL,
        'uploadedAt': Timestamp.now(),
      });
      print('Image URL saved to Firestore successfully.');
    } catch (e) {
      print('Error saving image URL to Firestore: $e');
    }
  }




  //Create budget entry
  Future<String> createBudgetEntry(String journalId) async {
    try {
      String? userId = getCurrentUserId();

      //check if budget was already created today
      QuerySnapshot snapshot = await _db
          .collection('budgets')
          .where('journalId', isEqualTo: journalId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print("Budget entry for today already exists.");
        return snapshot.docs.first.id;
      }

      //create new one if no budget was created today
      DocumentReference budget = await _db
          .collection('budgets')
          .add({'amount': 0, 'journalId': journalId});

      return budget.id;
    } catch (e) {
      print("Error creating budget: $e");
      throw e;
    }
  }

  //set or update budget amount
  Future<void> setBudgetAmount(String journalId, double amount) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('budgets')
          .where('journalId', isEqualTo: journalId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Update the existing document with the new amount
        String budgetId = snapshot.docs.first.id;
        await _db.collection('budgets').doc(budgetId).update({
          'amount': amount,
        });
        print("Budget amount updated successfully for journal ID: $journalId");
      } else {
        await _db.collection('budgets').add({
          'amount': amount,
          'journalId': journalId,
        });
        print(
            "New budget entry created with amount: $amount for journal ID: $journalId");
      }
    } catch (e) {
      print("Error setting budget amount: $e");
    }
  }

  // Method to fetch the budgetId associated with a specific journalId
  Future<String?> getBudgetIdForJournal(String? journalId) async {
    try {
      DocumentSnapshot journalDoc =
          await _db.collection('journals').doc(journalId).get();

      // Check if the journal entry exists
      if (journalDoc.exists) {
        return journalDoc['budget'] as String?;
      } else {
        print('Journal entry not found for the given ID');
        return null;
      }
    } catch (e) {
      print('Error fetching budgetId for journal: $e');
      return null;
    }
  }

  Future<double?> getBudgetAmount(String budgetId) async {
    try {
      final budgetDoc = await FirebaseFirestore.instance
          .collection('budgets')
          .doc(budgetId)
          .get();

      if (budgetDoc.exists && budgetDoc.data() != null) {
        return budgetDoc['amount'] as double?;
      }
      return null;
    } catch (e) {
      print("Error retrieving budget amount: $e");
      return null;
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
    return _db.collection(collection).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
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
