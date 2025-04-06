import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Collections for transactions and categories
  final CollectionReference transactions = FirebaseFirestore.instance.collection('transactions');
  final CollectionReference categories = FirebaseFirestore.instance.collection('categories');

  // -------------------------------
  // Transactions CRUD
  // -------------------------------

  // Create a new transaction
  Future<void> addTransaction(double montant, String type, String category, String description) {
    return transactions.add({
      'montant': montant,
      'type': type,
      'category': category,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Retrieve all transactions (ordered by timestamp descending)
  Stream<QuerySnapshot> getTransactions() {
    return transactions.orderBy('timestamp', descending: true).snapshots();
  }

  // Update an existing transaction
  Future<void> updateTransaction(String docID, double montant, String type, String category, String description) {
    return transactions.doc(docID).update({
      'montant': montant,
      'type': type,
      'category': category,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Delete a transaction
  Future<void> deleteTransaction(String docID) {
    return transactions.doc(docID).delete();
  }

  // -------------------------------
  // Categories CRUD
  // -------------------------------

  // Create a new category
  Future<void> addCategory(String name) {
    return categories.add({
      'name': name,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Retrieve all categories (ordered by timestamp descending)
  Stream<QuerySnapshot> getCategories() {
    return categories.orderBy('timestamp', descending: true).snapshots();
  }

  // Update an existing category
  Future<void> updateCategory(String docID, String name) {
    return categories.doc(docID).update({
      'name': name,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Delete a category
  Future<void> deleteCategory(String docID) {
    return categories.doc(docID).delete();
  }
}
