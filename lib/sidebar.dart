import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import User class

class AppSidebar extends StatelessWidget {
  final VoidCallback onLogout;
  final Function(String) onCategorySelected;
  final String selectedCategory;
  final List<String> categories;
  final User currentUser;
  final VoidCallback onTodaySelected;
  final VoidCallback onUpcomingSelected;
  final VoidCallback onCompletedSelected;
  final VoidCallback onTrashSelected;
  final VoidCallback onAddCategory;
  final Function(String) onEditCategory;
  final Function(String) onDeleteCategory;

  const AppSidebar({
    super.key,
    required this.onLogout,
    required this.onCategorySelected,
    required this.selectedCategory,
    required this.categories,
    required this.currentUser,
    required this.onTodaySelected,
    required this.onUpcomingSelected,
    required this.onCompletedSelected,
    required this.onTrashSelected,
    required this.onAddCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(currentUser.displayName ?? 'Pengguna'),
            accountEmail: Text(currentUser.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (currentUser.displayName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 40.0, color: Colors.blue),
              ),
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Semua Tugas'),
            selected: selectedCategory == 'Semua',
            onTap: () => onCategorySelected('Semua'),
          ),
          ListTile(
            leading: const Icon(Icons.today),
            title: const Text('Hari Ini'),
            onTap: onTodaySelected,
          ),
          ListTile(
            leading: const Icon(Icons.upcoming),
            title: const Text('Mendatang'),
            onTap: onUpcomingSelected,
          ),
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Selesai'),
            onTap: onCompletedSelected,
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Sampah'),
            onTap: onTrashSelected,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Kategori',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...categories.where((cat) => cat != 'Semua').map((category) {
            return ListTile(
              leading: const Icon(Icons.folder),
              title: Text(category),
              selected: selectedCategory == category,
              onTap: () => onCategorySelected(category),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => onEditCategory(category),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => onDeleteCategory(category),
                  ),
                ],
              ),
            );
          }),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Tambah Kategori'),
            onTap: onAddCategory,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
} 