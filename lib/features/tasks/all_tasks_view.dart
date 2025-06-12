import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/task_card.dart';
import '../../main.dart'; // Import Task class

class AllTasksView extends StatelessWidget {
  final String selectedCategory;
  final String searchQuery;
  final CollectionReference tasksCollection;
  final Function(Task) onToggleCompletion;
  final Function(Task) onToggleTrash;
  final Function(Task) onEditTask;
  final Function(Task) onDeleteTask;

  const AllTasksView({
    super.key,
    required this.selectedCategory,
    required this.searchQuery,
    required this.tasksCollection,
    required this.onToggleCompletion,
    required this.onToggleTrash,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Silakan login untuk melihat tugas.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: tasksCollection
          .where('isCompleted', isEqualTo: false) // Filter for incomplete tasks
          .where('isTrashed', isEqualTo: false) // Filter out trashed tasks
          .orderBy('timestamp', descending: true) // Order by timestamp or dueDate
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Tidak ada tugas yang tersedia.'));
        }

        final allTasks = snapshot.data!.docs.map((doc) => Task.fromFirestore(doc)).toList();

        final filteredTasks = allTasks.where((task) {
          final title = task.title.toLowerCase();
          final category = task.category.toLowerCase();

          final matchesSearch = title.contains(searchQuery.toLowerCase());
          final matchesCategory = selectedCategory == 'Semua' || category == selectedCategory.toLowerCase();

          return matchesSearch && matchesCategory;
        }).toList();

        if (filteredTasks.isEmpty) {
          return const Center(child: Text('Tidak ada tugas yang cocok dengan filter Anda.'));
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];
            return TaskCard(
              task: task,
              onToggleCompletion: () => onToggleCompletion(task),
              onToggleTrash: () => onToggleTrash(task),
              onEdit: () => onEditTask(task),
              onDelete: () => onDeleteTask(task),
            );
          },
        );
      },
    );
  }
} 