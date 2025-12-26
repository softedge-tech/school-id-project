import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth_provider.dart';

class ClassDetailScreen extends StatefulWidget {
  final String schoolId;
  final String classId;

  const ClassDetailScreen({
    super.key,
    required this.schoolId,
    required this.classId,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<ClassProvider>().loadClass(
          widget.schoolId,
          widget.classId,
        );
    await context.read<StudentProvider>().loadStudents(
          widget.schoolId,
          widget.classId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ClassProvider>(
          builder: (context, provider, child) {
            if (provider.selectedClass != null) {
              return Text('Class ${provider.selectedClass!.className}');
            }
            return const Text('Class Details');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer2<ClassProvider, StudentProvider>(
        builder: (context, classProvider, studentProvider, child) {
          if (classProvider.isLoading || studentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final classModel = classProvider.selectedClass;
          if (classModel == null) {
            return const Center(child: Text('Class not found'));
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classModel.className,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Teacher Login: ${classModel.teacherLoginId}'),
                    Text(
                      'Total Students: ${studentProvider.students.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Students',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (studentProvider.students.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _exportStudentData(context),
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: studentProvider.students.isEmpty
                    ? const Center(
                        child: Text('No students found in this class'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: studentProvider.students.length,
                        itemBuilder: (context, index) {
                          final student = studentProvider.students[index];
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
                              subtitle: Text(
                                'Roll: ${student.rollNumber}\n'
                                'Contact: ${student.contactNumber}',
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Text('View Details'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'view') {
                                    _showStudentDetails(context, student);
                                  } else if (value == 'delete') {
                                    _confirmDelete(context, student);
                                  }
                                },
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

  void _showStudentDetails(BuildContext context, student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (student.photoUrl != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      student.photoUrl!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailRow('Roll Number', student.rollNumber),
              _buildDetailRow("Father's Name", student.fatherName),
              _buildDetailRow("Mother's Name", student.motherName),
              _buildDetailRow('Contact', student.contactNumber),
              if (student.bloodGroup != null)
                _buildDetailRow('Blood Group', student.bloodGroup!),
              _buildDetailRow('Address', student.address),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await context.read<StudentProvider>().deleteStudent(
                    widget.schoolId,
                    widget.classId,
                    student.id,
                  );
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _exportStudentData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon'),
      ),
    );
  }
}