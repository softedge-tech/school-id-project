import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth_provider.dart';

class SchoolDetailScreen extends StatefulWidget {
  final String schoolId;

  const SchoolDetailScreen({super.key, required this.schoolId});

  @override
  State<SchoolDetailScreen> createState() => _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends State<SchoolDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<SchoolProvider>().loadSchool(widget.schoolId);
    await context.read<ClassProvider>().loadClasses(widget.schoolId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<SchoolProvider>(
          builder: (context, provider, child) {
            if (provider.selectedSchool != null) {
              return Text(provider.selectedSchool!.name);
            }
            return const Text('School Details');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer2<SchoolProvider, ClassProvider>(
        builder: (context, schoolProvider, classProvider, child) {
          if (schoolProvider.isLoading || classProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final school = schoolProvider.selectedSchool;
          if (school == null) {
            return const Center(child: Text('School not found'));
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
                      school.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Contact: ${school.contactNumber}'),
                    Text('Location: ${school.location}'),
                    Text('School ID: ${school.schoolLoginId}'),
                    Text('ID Prefix: ${school.idCardPrefix}'),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Classes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${classProvider.classes.length} total',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: classProvider.classes.isEmpty
                    ? const Center(child: Text('No classes found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: classProvider.classes.length,
                        itemBuilder: (context, index) {
                          final classModel = classProvider.classes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(classModel.className[0]),
                              ),
                              title: Text(classModel.className),
                              subtitle: Text(
                                'Teacher: ${classModel.teacherLoginId}',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => context.go(
                                '/class/${widget.schoolId}/${classModel.id}',
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
}