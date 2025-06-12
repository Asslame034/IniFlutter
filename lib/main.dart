import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'features/tasks/all_tasks_view.dart';
import 'features/tasks/today_tasks_view.dart';
import 'features/tasks/upcoming_tasks_view.dart';
import 'features/tasks/completed_tasks_view.dart';
import 'features/tasks/trash_tasks_view.dart';
import 'sidebar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/google_calendar_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clario',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        textTheme: GoogleFonts.signikaNegativeTextTheme(),
      ),
      home: Scaffold(
        body: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _currentUser;
  String? _googleAccessToken;

  @override
  void initState() {
    super.initState();
    _checkRedirectResult();

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      print("[authStateChanges] User state changed: ${user?.email ?? 'null'}");
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
      } else {
        setState(() {
          _currentUser = null;
          _googleAccessToken = null;
        });
      }
    });
  }

  Future<void> _checkRedirectResult() async {
    print("[_checkRedirectResult] Attempting to get redirect result...");
    try {
      final UserCredential? userCredential = await FirebaseAuth.instance.getRedirectResult();

      if (userCredential != null && userCredential.user != null) {
        print("[_checkRedirectResult] Redirect result found user: ${userCredential.user!.email}");
        if (userCredential.credential is GoogleAuthCredential) {
          final GoogleAuthCredential googleCredential = userCredential.credential as GoogleAuthCredential;
          _googleAccessToken = googleCredential.accessToken;
          print("[_checkRedirectResult] Google Access Token (from redirect): $_googleAccessToken");
        }
      } else {
        print("[_checkRedirectResult] No redirect result, or user is null.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Redirect Result Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('[_checkRedirectResult] Redirect Result Error (Terminal): ${e.toString()}');
    }
  }

  Future<void> _signInWithGoogle() async {
    print("[_signInWithGoogle] Attempting Google sign-in...");
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: [
        'email',
        'https://www.googleapis.com/auth/calendar.events',
        'https://www.googleapis.com/auth/userinfo.profile',
      ],
      clientId: kIsWeb ? '407083298479-46baq2i7ie2kri1q6b0iik1l5ai6fudd.apps.googleusercontent.com' : null,
      );

      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        print("[_signInWithGoogle] Attempting Google Sign-In for web with redirect.");
        googleUser = await googleSignIn.signIn();
      } else {
        print("[_signInWithGoogle] Attempting Google Sign-In for non-web.");
        googleUser = await googleSignIn.signIn();
      }

      if (googleUser == null) {
        print("[_signInWithGoogle] Google sign-in was canceled.");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      _googleAccessToken = googleAuth.accessToken;
      print("[_signInWithGoogle] Google Access Token: $_googleAccessToken");

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      print("[_signInWithGoogle] Firebase sign-in successful.");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal login dengan Google: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('[_signInWithGoogle] Gagal login dengan Google (Terminal): ${e.toString()}');
    }
  }

  Future<void> _signOut() async {
    try {
      print("[_signOut] Attempting Firebase sign out...");
      await FirebaseAuth.instance.signOut();
      print("[_signOut] Firebase sign out successful.");
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '407083298479-46baq2i7ie2kri1q6b0iik1l5ai6fudd.apps.googleusercontent.com' : null,
      );
      await googleSignIn.signOut();
      print("[_signOut] Google Sign-Out successful.");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat logout. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('[_signOut] Error during sign out (Terminal): ${e.toString()}');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (authSnapshot.hasError) {
          return Center(child: Text('Auth state error: ${authSnapshot.error}'));
        } else {
          final User? currentUser = authSnapshot.data;
          return currentUser == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/Clario_logo.png',
                        height: 200,
                      ),
                      Text(
                        'Selamat datang di Clario',
                        style: GoogleFonts.comicNeue(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: Image.asset(
                          'assets/google_logo.png',
                          height: 24.0,
                        ),
                        label: const Text('Masuk dengan Google'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.white,
                          minimumSize: const Size(200, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : HomeScreen(
                  currentUser: currentUser!,
                  onLogout: _signOut,
                  googleAccessToken: _googleAccessToken,
                );
        }
      },
    );
  }
}

class Task {
  final String id;
  String title;
  String? description;
  DateTime? dueDate;
  String category;
  bool isCompleted;
  bool isTrashed;
  String? calendarEventId;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    required this.category,
    this.isCompleted = false,
    this.isTrashed = false,
    this.calendarEventId,
  });

  // Factory constructor to create a Task from a Firestore DocumentSnapshot
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      category: data['category'] ?? 'Semua',
      isCompleted: data['isCompleted'] ?? false,
      isTrashed: data['isTrashed'] ?? false,
      calendarEventId: data['calendarEventId'],
    );
  }

  // Convert Task to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'category': category,
      'isCompleted': isCompleted,
      'isTrashed': isTrashed,
      'calendarEventId': calendarEventId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class HomeScreen extends StatefulWidget {
  final User currentUser;
  final VoidCallback onLogout;
  final String? googleAccessToken;

  const HomeScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
    this.googleAccessToken,
  });

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String _currentViewMode = 'all';
  final List<String> _categories = ['Semua', 'Pekerjaan', 'Pribadi', 'Keluarga', 'Lainnya'];
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  CollectionReference get _tasksCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.currentUser.uid)
      .collection('tasks');

  // Add a task
  Future<void> _addTask(Task task) async {
    try {
      // Sync with Google Calendar if due date is set
      if (task.dueDate != null) {
        await _calendarService.syncTaskToCalendar(task);
      }
      
      await _tasksCollection.add(task.toFirestore());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas berhasil ditambahkan!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan tugas: ${e.toString()}')),
      );
    }
  }

  // Update a task
  Future<void> _updateTask(Task task) async {
    try {
      // Update Google Calendar event if due date is set
      if (task.dueDate != null) {
        if (task.calendarEventId != null) {
          // Delete old event
          await _calendarService.deleteTaskFromCalendar(task.calendarEventId!);
        }
        // Create new event
        await _calendarService.syncTaskToCalendar(task);
      }
      
      await _tasksCollection.doc(task.id).update(task.toFirestore());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas berhasil diperbarui!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui tugas: ${e.toString()}')),
      );
    }
  }

  // Delete a task (permanently)
  Future<void> _deleteTask(Task task) async {
    try {
      // Delete from Google Calendar if event exists
      if (task.calendarEventId != null) {
        await _calendarService.deleteTaskFromCalendar(task.calendarEventId!);
      }
      
      await _tasksCollection.doc(task.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas berhasil dihapus permanen.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus tugas: ${e.toString()}')),
      );
    }
  }

  // Move task to trash / restore from trash
  Future<void> _toggleTaskTrash(Task task) async {
    try {
      await _tasksCollection.doc(task.id).update({'isTrashed': !task.isTrashed});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tugas ${task.isTrashed ? 'dipulihkan' : 'dipindahkan ke sampah'}.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status sampah tugas: ${e.toString()}')),
      );
    }
  }

  // Toggle task completion status
  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      await _tasksCollection.doc(task.id).update({'isCompleted': !task.isCompleted});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tugas ditandai ${task.isCompleted ? 'belum selesai' : 'selesai'}.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status selesai tugas: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _currentViewMode = 'all';
    });
  }

  void _onTodaySelected() {
    setState(() {
      _currentViewMode = 'today';
    });
  }

  void _onUpcomingSelected() {
    setState(() {
      _currentViewMode = 'upcoming';
    });
  }

  void _onCompletedSelected() {
    setState(() {
      _currentViewMode = 'completed';
    });
  }

  void _onTrashSelected() {
    setState(() {
      _currentViewMode = 'trash';
    });
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
          onSubmitted: (value) {
            if (value.isNotEmpty && !_categories.contains(value)) {
              setState(() {
                _categories.add(value);
                _selectedCategory = value;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kategori "$value" berhasil ditambahkan!')),
              );
            } else if (_categories.contains(value)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kategori "$value" sudah ada.')),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _editCategory(String oldCategory) {
    TextEditingController editController = TextEditingController(text: oldCategory);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Nama Kategori'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: 'Nama Kategori Baru'),
          onSubmitted: (newValue) {
            if (newValue.isNotEmpty &&
                newValue != oldCategory &&
                !_categories.contains(newValue)) {
              setState(() {
                int index = _categories.indexOf(oldCategory);
                if (index != -1) {
                  _categories[index] = newValue;
                  if (_selectedCategory == oldCategory) {
                    _selectedCategory = newValue;
                  }
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kategori "$oldCategory" berhasil diubah menjadi "$newValue"!')),
              );
            } else if (newValue == oldCategory) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tidak ada perubahan pada nama kategori.')),
              );
            } else if (_categories.contains(newValue)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kategori "$newValue" sudah ada.')),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String category) {
    if (category == 'Semua' || category == 'Pekerjaan' || category == 'Pribadi' || category == 'Keluarga' || category == 'Lainnya') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori bawaan tidak dapat dihapus.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Apakah Anda yakin ingin menghapus kategori "$category"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _categories.remove(category);
                if (_selectedCategory == category) {
                  _selectedCategory = 'Semua';
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kategori "$category" berhasil dihapus.')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDueDate;
    String? selectedCategory = _categories.first; // Default to the first category

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Tugas Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Judul Tugas'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)'),
                maxLines: 3,
              ),
              ListTile(
                title: Text(selectedDueDate == null
                    ? 'Pilih Tanggal Jatuh Tempo (Opsional)'
                    : 'Jatuh Tempo: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year} ${selectedDueDate!.hour}:${selectedDueDate!.minute}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDueDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (pickedDate != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDueDate ?? DateTime.now()),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        selectedDueDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final newTask = Task(
                  id: '',
                  title: titleController.text,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  dueDate: selectedDueDate,
                  category: selectedCategory ?? _categories.first,
                );
                _addTask(newTask);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Judul tugas tidak boleh kosong.')),
                );
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    final TextEditingController titleController = TextEditingController(text: task.title);
    final TextEditingController descriptionController = TextEditingController(text: task.description);
    DateTime? selectedDueDate = task.dueDate;
    String? selectedCategory = task.category;

    // Ensure selectedCategory is one of the existing categories, otherwise default to first
    if (!_categories.contains(selectedCategory)) {
      selectedCategory = _categories.first;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Edit Tugas'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Judul Tugas'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)'),
                    maxLines: 3,
                  ),
                  ListTile(
                    title: Text(selectedDueDate == null
                        ? 'Pilih Tanggal Jatuh Tempo (Opsional)'
                        : 'Jatuh Tempo: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year} ${selectedDueDate!.hour}:${selectedDueDate!.minute}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (pickedDate != null) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDueDate ?? DateTime.now()),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedDueDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    task.title = titleController.text;
                    task.description = descriptionController.text.isEmpty ? null : descriptionController.text;
                    task.dueDate = selectedDueDate;
                    task.category = selectedCategory ?? _categories.first;
                    _updateTask(task);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Judul tugas tidak boleh kosong.')),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentViewMode) {
      case 'all':
        return AllTasksView(
          selectedCategory: _selectedCategory,
          searchQuery: _searchQuery,
          tasksCollection: _tasksCollection,
          onToggleCompletion: _toggleTaskCompletion,
          onToggleTrash: _toggleTaskTrash,
          onEditTask: _showEditTaskDialog,
          onDeleteTask: _deleteTask,
        );
      case 'today':
        return TodayTasksView(
          searchQuery: _searchQuery,
          tasksCollection: _tasksCollection,
          onToggleCompletion: _toggleTaskCompletion,
          onToggleTrash: _toggleTaskTrash,
          onEditTask: _showEditTaskDialog,
          onDeleteTask: _deleteTask,
        );
      case 'upcoming':
        return UpcomingTasksView(
          searchQuery: _searchQuery,
          tasksCollection: _tasksCollection,
          onToggleCompletion: _toggleTaskCompletion,
          onToggleTrash: _toggleTaskTrash,
          onEditTask: _showEditTaskDialog,
          onDeleteTask: _deleteTask,
        );
      case 'completed':
        return CompletedTasksView(
          searchQuery: _searchQuery,
          tasksCollection: _tasksCollection,
          onToggleCompletion: _toggleTaskCompletion,
          onToggleTrash: _toggleTaskTrash,
          onEditTask: _showEditTaskDialog,
          onDeleteTask: _deleteTask,
        );
      case 'trash':
        return TrashTasksView(
          searchQuery: _searchQuery,
          tasksCollection: _tasksCollection,
          onToggleCompletion: _toggleTaskCompletion,
          onToggleTrash: _toggleTaskTrash,
          onEditTask: _showEditTaskDialog,
          onDeleteTask: _deleteTask,
        );
      default:
        return AllTasksView(
          selectedCategory: _selectedCategory,
          searchQuery: _searchQuery,
          tasksCollection: _tasksCollection,
          onToggleCompletion: _toggleTaskCompletion,
          onToggleTrash: _toggleTaskTrash,
          onEditTask: _showEditTaskDialog,
          onDeleteTask: _deleteTask,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clario',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
                fontFamily: 'ComicNeue',
              ),
            ),
            Text(
              '${widget.currentUser.displayName ?? 'Pengguna'} - ${_selectedCategory == 'Semua' ? 'Semua Kategori' : _selectedCategory}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: 150,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari tugas...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      drawer: AppSidebar(
        onLogout: widget.onLogout,
        onCategorySelected: _onCategorySelected,
        selectedCategory: _selectedCategory,
        categories: _categories,
        currentUser: widget.currentUser,
        onTodaySelected: _onTodaySelected,
        onUpcomingSelected: _onUpcomingSelected,
        onCompletedSelected: _onCompletedSelected,
        onTrashSelected: _onTrashSelected,
        onAddCategory: _addCategory,
        onEditCategory: _editCategory,
        onDeleteCategory: _deleteCategory,
      ),
      body: _buildCurrentView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTaskDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
