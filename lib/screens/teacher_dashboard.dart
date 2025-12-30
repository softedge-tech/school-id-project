import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../auth_provider.dart';
import '../../models.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String? _schoolId;
  String? _classId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      setState(() {
        _schoolId = user.schoolId;
        _classId = user.classId;
      });

      if (_schoolId != null && _classId != null) {
        await context.read<StudentProvider>().loadStudents(
          _schoolId!,
          _classId!,
        );
        await context.read<ClassProvider>().loadClass(_schoolId!, _classId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_schoolId == null || _classId == null) {
      return const Scaffold(
        body: Center(child: Text('Invalid teacher configuration')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Consumer<ClassProvider>(
          builder: (context, provider, child) {
            if (provider.selectedClass != null) {
              return Text('Class: ${provider.selectedClass!.className}');
            }
            return const Text('Teacher Dashboard');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareParentFormLink(context),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            print(provider.error);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('No students yet'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _shareParentFormLink(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Parent Form'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Total Students: ${provider.students.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _shareParentFormLink(context),
                      icon: const Icon(Icons.link),
                      label: const Text('Share Form'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.students.length,
                  itemBuilder: (context, index) {
                    final student = provider.students[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: student.photoUrl != null
                              ? NetworkImage(student.photoUrl!)
                              : null,
                          child: student.photoUrl == null
                              ? Text(student.name[0])
                              : null,
                        ),
                        title: Text(student.name),
                        subtitle: Text('Roll: ${student.rollNumber}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => context.go(
                            '/teacher/edit-student/$_schoolId/$_classId/${student.id}',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _shareParentFormLink(BuildContext context) {
    final classProvider = context.read<ClassProvider>();
    final link = classProvider.generateParentFormLink(_schoolId!, _classId!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parent Form Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Share this link with parents to collect student data:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(link, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Share.share(
                'Submit your child\'s ID card details here: $link',
                subject: 'Student ID Card Form',
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
