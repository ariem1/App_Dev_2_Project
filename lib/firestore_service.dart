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
  Future<bool> journalEntryExistsForToday(String currentUserId) async {
    try {
      // Get the current date
      DateTime now = DateTime.now();
      DateTime startOfDay =
          DateTime(now.year, now.month, now.day); // Midnight of today
      DateTime endOfDay = DateTime(
          now.year, now.month, now.day, 23, 59, 59, 999); // End of today

      QuerySnapshot snapshot = await _db
          .collection('journals')
          .where('userId', isEqualTo: currentUserId)
          .where('entryDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('entryDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

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
    String userId,
  ) async {
    try {
      // String? userId = getCurrentUserId();

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
  Future<void> updateJournalEntry(
      String entry, String desc, String title, String? currentUserId) async {
    try {
      String? journalId = await getJournalIdByUserIdAndDate_2(currentUserId!);

      print('Journal id: $journalId');
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

  //Fetch Journal Data
  Future<Map<String, dynamic>> fetchJournalData(String? userId) async {
    try {
      if (userId == null) {
        print('Error: User ID is null.');
        return {};
      }

      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay =
          startOfDay.add(Duration(days: 1)).subtract(Duration(seconds: 1));

      // Convert to Firestore Timestamps
      Timestamp startTimestamp = Timestamp.fromDate(startOfDay);
      Timestamp endTimestamp = Timestamp.fromDate(endOfDay);

      // Query the journals collection for today's entries for the user
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('journals')
          .where('userId', isEqualTo: userId)
          .where('entryDate', isGreaterThanOrEqualTo: startTimestamp)
          .where('entryDate', isLessThanOrEqualTo: endTimestamp)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No journal entry found for this user on this date');
        return {};
      }

      // Assuming only one entry per day, fetch the first document
      var document = snapshot.docs.first;

      return {
        'journalId': document.id, // Document ID as journalId
        'title': document.get('title') ?? '',
        'description': document.get('description') ?? '',
        'content': document.get('content') ?? '',
        'mood': document.get('mood') ?? -1,
        'entryDate': document.get('entryDate') ?? '',
        'water': document.get('water') ?? 0,
        'imagePath': document.get('imagePath') ?? '',
        'budget': document.get('budget') ?? 0,
      };
    } catch (e) {
      print('Error fetching journal entry: $e');
      return {};
    }
  }

  //Fetches the data of a journal by date -- for journal page
  Future<Map<String, dynamic>> fetchJournalDataByDateAndUser(
      DateTime selectedDate, String? userId) async {
    // Get start and end of the target day
    DateTime startOfDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));
    //String? userId = getCurrentUserId();

    print('Journal: for $userId');

    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('journals')
          .where('userId', isEqualTo: userId)
          .where('entryDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('entryDate', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      var querySnapshotImage = await FirebaseFirestore.instance
          .collection('images')
          .where('userId', isEqualTo: userId)
          .get();

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
        'imagePath': document.get('imagePath') ?? '',
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
  Future<String?> getJournalIdByUserIdAndDate(String currentUserId) async {
    try {
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
          .where('userId', isEqualTo: currentUserId)
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

  // Returns the Journal Id for the day
  Future<String?> getJournalIdByUserIdAndDate_2(String currentUserId) async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay =
          startOfDay.add(Duration(days: 1)).subtract(Duration(seconds: 1));

      // Convert to Firestore's Timestamp
      Timestamp startTimestamp = Timestamp.fromDate(startOfDay);
      Timestamp endTimestamp = Timestamp.fromDate(endOfDay);

      // Query the Firestore collection
      QuerySnapshot snapshot = await _db
          .collection('journals')
          .where('userId', isEqualTo: currentUserId)
          .where('entryDate', isGreaterThanOrEqualTo: startTimestamp)
          .where('entryDate', isLessThanOrEqualTo: endTimestamp)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No journal entry found for this user on this date');
        return null;
      }

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
      Reference storage =
          FirebaseStorage.instance.ref().child('images/$fileName');

      // Upload the image file
      UploadTask uploadTask = storage.putFile(image);

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get the image's download URL
      String downloadURL = await snapshot.ref.getDownloadURL();

      if (downloadURL != "") {
        print('Download URL: $downloadURL');
      } else {
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
        //'journalId':
      });
      print('Image URL saved to Firestore successfully.');
    } catch (e) {
      print('Error saving image URL to Firestore: $e');
    }
  }

/////////// TASK //////////

// Add a journal and return task -- done in the Home Page
  Future<Map<String, dynamic>?> addtask(String userId, String task) async {
    try {
      // Add a new task entry
      DocumentReference taskEntry = await _db.collection('tasks').add({
        'userId': userId,
        'entryDate':
            Timestamp.fromDate(DateTime.now()), // current date
        'done': false,
        'dueDate': '',
        'description': '',
        'taskName': task,
        'location': '',
      });

      // Get the document ID (taskId) from the DocumentReference
      String taskId = taskEntry.id;

      // Fetch the newly created document
      DocumentSnapshot taskSnapshot = await taskEntry.get();

      print('Task entry: $taskId');
      return {
        'taskId': taskId,
        'userId': taskSnapshot.get('userId'),
        'entryDate': taskSnapshot.get('entryDate'),
        'done': taskSnapshot.get('done'),
        'dueDate': taskSnapshot.get('dueDate'),
        'description': taskSnapshot.get('description'),
        'location': taskSnapshot.get('location'),
        'taskName': taskSnapshot.get('taskName'),
      };
    } catch (e) {
      print('Error adding task: $e');
      return null;
    }
  }

  // Fetches all tasks for a specific user
  Future<List<Map<String, dynamic>>> fetchAllTasksByUser(String userId) async {
    try {
      print('Fetching all tasks for user ID: $userId');

      // Query the 'tasks' collection to get all tasks for the given user ID
      var querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      // Check if there are any tasks
      if (querySnapshot.docs.isEmpty) {
        print('No tasks found for user ID: $userId');
        return [];
      }

      // Map the documents to a list of maps
      return querySnapshot.docs.map((doc) {
        return {
          'taskId': doc.id ?? '',
          'userId': doc.get('userId') ?? '',
          'entryDate': doc.get('entryDate') ?? '',
          'done': doc.get('done') ?? false,
          'dueDate': doc.get('dueDate') ?? '',
          'description': doc.get('description') ?? '',
          'taskName': doc.get('taskName') ?? '',
          'location': doc.get('location') ?? '',
        };
      }).toList();
      print('Tasks fetched for userId: ${userId}');
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchATask(String taskId) async {
    try {

      var docSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();

      if (docSnapshot.exists) {
        return {
          'title': docSnapshot.data()?['title'] ?? '',
          'description': docSnapshot.data()?['description'] ?? '',
          'done': docSnapshot.data()?['done'] ?? '',
          'dueDate': docSnapshot.data()?['dueDate'] ?? '',
          'entryDate': docSnapshot.data()?['entryDate'] ?? '',
          'location': docSnapshot.data()?['location'] ?? '',
          'taskName': docSnapshot.data()?['taskName'] ?? '',
        };
      } else {
        print('Task with ID $taskId not found.');
        return {};
      }
    } catch (e) {
      print('Error fetching task with ID $taskId: $e');
      return {};
    }
  }



  // Update task completion
  Future<void> updateTaskCompletion(String taskId, bool done) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({'done': done});
      print('Task $taskId updated to done: $done');
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  // Update task location
  Future<void> updateTaskLocation(String taskId, String location) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({'location': location});
      print('Task $taskId location updated: $location');
    } catch (e) {
      print('Error updating task: $e');
    }
  }


  //////////////// BUDGET /////////
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
  /////////WATER////////
  Future<void> incrementCupsDrank(String journalId) async {
    try {
      DocumentReference journalRef =
      FirebaseFirestore.instance.collection('journals').doc(journalId);

      await journalRef.update({
        'water': FieldValue.increment(1),
      });
      print("Cup count incremented.");
    } catch (e) {
      print("Error incrementing cupsDrank: $e");
    }
  }

}