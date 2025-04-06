import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gestion_financiere/services/firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();

  // Controllers for transaction fields
  final TextEditingController montantController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Dropdown selections for type and category
  String _selectedType = 'recette';
  String? _selectedCategory;

  // List of categories loaded from Firestore
  List<String> categoriesList = [];

  // Flutter local notifications plugin instance
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Listen to the categories collection and update the list
    firestoreService.getCategories().listen((snapshot) {
      List<String> cats = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['name'] as String;
      }).toList();
      setState(() {
        categoriesList = cats;
        if (_selectedCategory == null && cats.isNotEmpty) {
          _selectedCategory = cats[0];
        }
      });
    });
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Notification',
      message,
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  void openTransactionDialog({String? docID, Map<String, dynamic>? transactionData}) {
    bool isUpdate = docID != null;
    if (isUpdate && transactionData != null) {
      montantController.text = transactionData['montant'].toString();
      descriptionController.text = transactionData['description'];
      _selectedType = transactionData['type'];
      _selectedCategory = transactionData['category'];
    } else {
      montantController.clear();
      descriptionController.clear();
      _selectedType = 'recette';
      if (categoriesList.isNotEmpty) {
        _selectedCategory = categoriesList[0];
      } else {
        _selectedCategory = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUpdate ? 'Update Transaction' : 'New Transaction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: montantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'recette', child: Text('Recette')),
                  DropdownMenuItem(value: 'dépense', child: Text('Dépense')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Type',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: categoriesList.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              double? montant = double.tryParse(montantController.text);
              if (montant == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid montant')),
                );
                return;
              }
              String type = _selectedType;
              String? category = _selectedCategory;
              String description = descriptionController.text;

              if (category == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a category')),
                );
                return;
              }

              if (isUpdate) {
                firestoreService.updateTransaction(docID!, montant, type, category, description);
              } else {
                firestoreService.addTransaction(montant, type, category, description);
              }
              Navigator.pop(context);
            },
            child: Text(isUpdate ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Check if categories list is empty
          if (categoriesList.isNotEmpty) {
            openTransactionDialog();
          } else {
            _showNotification('Les catégories sont vides');
          }
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List transactionsList = snapshot.data!.docs;
            if (transactionsList.isEmpty) {
              return const Center(child: Text('No transactions yet. Add one!'));
            }
            return ListView.builder(
              itemCount: transactionsList.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = transactionsList[index];
                String docID = document.id;
                Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                double montant = data['montant'];
                String type = data['type'];
                String category = data['category'];
                String description = data['description'];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    title: Text('$category - $type'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Montant: $montant'),
                        Text('Description: $description'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            openTransactionDialog(docID: docID, transactionData: data);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            firestoreService.deleteTransaction(docID);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    montantController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
