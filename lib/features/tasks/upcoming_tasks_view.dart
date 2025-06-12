import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/task_card.dart';
import '../../main.dart'; // Import Task class

class UpcomingTasksView extends StatelessWidget {
  final String searchQuery;
  final CollectionReference tasksCollection;
  final Function(Task) onToggleCompletion;
  final Function(Task) onToggleTrash;
  final Function(Task) onEditTask;
  final Function(Task) onDeleteTask;

  const UpcomingTasksView({
    super.key,
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

    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: tasksCollection
          .where('dueDate', isGreaterThanOrEqualTo: startOfTomorrow)
          .where('isTrashed', isEqualTo: false)
          .where('isCompleted', isEqualTo: false)
          .orderBy('dueDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Tidak ada tugas mendatang.'));
        }

        final allTasks = snapshot.data!.docs.map((doc) => Task.fromFirestore(doc)).toList();

        final filteredTasks = allTasks.where((task) {
          final title = task.title.toLowerCase();
          return title.contains(searchQuery.toLowerCase());
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