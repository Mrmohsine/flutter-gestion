import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gestion_financiere/services/firestore.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController categoryController = TextEditingController();

  /// Opens a dialog to add or update a category.
  /// If [docID] and [currentName] are provided, it enters update mode.
  void openCategoryDialog({String? docID, String? currentName}) {
    bool isUpdate = docID != null;
    if (isUpdate && currentName != null) {
      categoryController.text = currentName;
    } else {
      categoryController.clear();
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUpdate ? 'Update Category' : 'Add Category'),
        content: TextField(
          controller: categoryController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              String name = categoryController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category name cannot be empty')),
                );
                return;
              }
              if (isUpdate) {
                firestoreService.updateCategory(docID!, name);
              } else {
                firestoreService.addCategory(name);
              }
              categoryController.clear();
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
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openCategoryDialog();
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List categoriesList = snapshot.data!.docs;
            if (categoriesList.isEmpty) {
              return const Center(child: Text('No categories yet. Add one!'));
            }
            return ListView.builder(
              itemCount: categoriesList.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = categoriesList[index];
                String docID = document.id;
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;
                String name = data['name'];
                return Card(
                  elevation: 2,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    title: Text(name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            openCategoryDialog(docID: docID, currentName: name);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            firestoreService.deleteCategory(docID);
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
    categoryController.dispose();
    super.dispose();
  }
}
