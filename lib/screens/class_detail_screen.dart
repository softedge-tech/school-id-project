import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:archive/archive.dart';
import '../../auth_provider.dart';
import 'dart:html' as html;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final GlobalKey _idCardKey = GlobalKey();
  bool _isGeneratingCards = false;
  Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<SchoolProvider>().loadSchool(widget.schoolId);
    await context.read<ClassProvider>().loadClass(
      widget.schoolId,
      widget.classId,
    );
    await context.read<StudentProvider>().loadStudents(
      widget.schoolId,
      widget.classId,
    );
  }

  // Demo data for testing
  List<Map<String, dynamic>> _getDemoStudents() {
    return [
      {
        'id': 'demo1',
        'name': 'Ahmed Ali Hassan',
        'rollNumber': '001',
        'fatherName': 'Ali Hassan Mohammed',
        'motherName': 'Fatima Ahmed',
        'contactNumber': '+971 50 123 4567',
        'bloodGroup': 'O+',
        'address': 'Al Khalidiya, Abu Dhabi, UAE',
        'photoUrl': 'https://via.placeholder.com/300',
      },
      {
        'id': 'demo2',
        'name': 'Sara Mohammed',
        'rollNumber': '002',
        'fatherName': 'Mohammed Abdullah',
        'motherName': 'Aisha Mohammed',
        'contactNumber': '+971 52 234 5678',
        'bloodGroup': 'A+',
        'address': 'Al Reem Island, Abu Dhabi, UAE',
        'photoUrl': 'https://via.placeholder.com/300',
      },
      {
        'id': 'demo3',
        'name': 'Omar Khalid',
        'rollNumber': '003',
        'fatherName': 'Khalid Ibrahim',
        'motherName': 'Noura Khalid',
        'contactNumber': '+971 55 345 6789',
        'bloodGroup': 'B+',
        'address': 'Khalifa City, Abu Dhabi, UAE',
        'photoUrl': 'https://via.placeholder.com/300',
      },
      {
        'id': 'demo4',
        'name': 'Layla Hassan',
        'rollNumber': '004',
        'fatherName': 'Hassan Ahmad',
        'motherName': 'Mariam Hassan',
        'contactNumber': '+971 56 456 7890',
        'bloodGroup': 'AB+',
        'address': 'Al Mushrif, Abu Dhabi, UAE',
        'photoUrl': 'https://via.placeholder.com/300',
      },
      {
        'id': 'demo5',
        'name': 'Yousef Abdullah',
        'rollNumber': '005',
        'fatherName': 'Abdullah Saeed',
        'motherName': 'Huda Abdullah',
        'contactNumber': '+971 50 567 8901',
        'bloodGroup': 'O-',
        'address': 'Al Bateen, Abu Dhabi, UAE',
        'photoUrl': 'https://via.placeholder.com/300',
      },
    ];
  }
  // Future<void> _loadData() async {
  //   await context.read<SchoolProvider>().loadSchool(widget.schoolId);
  //   await context.read<ClassProvider>().loadClasses(widget.schoolId);
  // }
  // final Map<String, Uint8List> _imageCache = {};

  Future<Uint8List?> _loadImageFromUrl(String path) async {
    if (_imageCache.containsKey(path)) {
      return _imageCache[path];
    }

    try {
      ByteData data;

      // ✅ Local asset
      if (path.startsWith('assets/')) {
        data = await rootBundle.load(path);
      }
      // ✅ Network image (Firebase / HTTPS)
      else if (path.startsWith('http://') || path.startsWith('https://')) {
        final bundle = NetworkAssetBundle(Uri.parse(path));
        data = await bundle.load(path);
      }
      // ❌ Invalid path
      else {
        debugPrint('Invalid image path: $path');
        return null;
      }

      final bytes = data.buffer.asUint8List();

      if (bytes.length < 100) return null;

      _imageCache[path] = bytes;
      return bytes;
    } catch (e) {
      debugPrint('Image load failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF001F3F), // Navy blue
        foregroundColor: Colors.white,
        title: Consumer<ClassProvider>(
          builder: (context, provider, child) {
            if (provider.selectedClass != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class ${provider.selectedClass!.className}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    provider.selectedClass!.teacherLoginId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              );
            }
            return const Text('Class Details');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer2<ClassProvider, StudentProvider>(
        builder: (context, classProvider, studentProvider, child) {
          if (classProvider.isLoading || studentProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF001F3F)),
              ),
            );
          }

          final classModel = classProvider.selectedClass;
          if (classModel == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Class not found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Use demo data if no students in database
          final students = studentProvider.students.isEmpty
              ? _getDemoStudents()
              : studentProvider.students
                    .map(
                      (s) => {
                        'id': s.id,
                        'name': s.name,
                        'rollNumber': s.rollNumber,
                        'fatherName': s.fatherName,
                        'motherName': s.motherName,
                        'contactNumber': s.contactNumber,
                        'bloodGroup': s.bloodGroup,
                        'address': s.address,
                        'photoUrl': s.photoUrl,
                        'admissionNumber': s.admissionNumber,
                        'batch': s.batch,
                        'phoneNumber': s.phoneNumber,
                        'dateOfBirth': s.dateOfBirth,
                      },
                    )
                    .toList();

          return Column(
            children: [
              // Class Info Header Card
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF001F3F), Color(0xFF003D7A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF001F3F).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  classModel.className,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Teacher: ${classModel.teacherLoginId}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_rounded,
                              color: Color(0xFF001F3F),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${students.length} Students Enrolled',
                              style: const TextStyle(
                                color: Color(0xFF001F3F),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Students Section Header
              Consumer<SchoolProvider>(
                builder: (context, School, child) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Students',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF001F3F),
                        ),
                      ),
                      const Spacer(),
                      if (students.isNotEmpty) ...[
                        ElevatedButton.icon(
                          onPressed: _isGeneratingCards
                              ? null
                              : () {
                                  final school = School.selectedSchool;
                                  _downloadAllIDCards(
                                    context,
                                    students,
                                    classModel,
                                    '${school!.frontIdCardUrl}',
                                    '${school.idCardPrefix}',
                                  );
                                },
                          icon: _isGeneratingCards
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 18),
                          label: Text(
                            _isGeneratingCards
                                ? 'Generating...'
                                : 'Download All ID Cards',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF001F3F),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _exportStudentData(context),
                          icon: const Icon(Icons.table_chart_rounded, size: 18),
                          label: const Text('Export Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF001F3F),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Color(0xFF001F3F),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Students List
              Expanded(
                child: students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No students found in this class',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF001F3F),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: const Color(
                                    0xFF001F3F,
                                  ).withOpacity(0.1),
                                  backgroundImage: student['photoUrl'] != null
                                      ? NetworkImage(
                                          student['photoUrl']!.toString(),
                                        )
                                      : null,
                                  child: student['photoUrl'] == null
                                      ? Text(
                                          student['name']
                                              .toString()[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Color(0xFF001F3F),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              title: Text(
                                student['name'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF001F3F),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.badge_outlined,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Roll: ${student['rollNumber']}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_outlined,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          student['contactNumber'].toString(),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              isThreeLine: true,
                              trailing: Container(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF001F3F,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Consumer<SchoolProvider>(
                                  builder: (context, School, child) =>
                                      PopupMenuButton(
                                        icon: const Icon(
                                          Icons.more_vert_rounded,
                                          color: Color(0xFF001F3F),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'view',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.visibility_outlined,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 12),
                                                Text('View Details'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'idcard',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.badge_outlined,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 12),
                                                Text('Download ID Card'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete_outline,
                                                  size: 20,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) async {
                                          if (value == 'view') {
                                            _showStudentDetails(
                                              context,
                                              student,
                                            );
                                          } else if (value == 'idcard') {
                                            final school =
                                                School.selectedSchool;
                                            await _downloadSingleIDCard(
                                              context,
                                              student,
                                              classModel,
                                              '${school!.frontIdCardUrl}',
                                              '${school.idCardPrefix}',
                                            );
                                          } else if (value == 'delete') {
                                            _confirmDelete(context, student);
                                          }
                                        },
                                      ),
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

  void _showStudentDetails(BuildContext context, dynamic student) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF001F3F), Color(0xFF003D7A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    if (student['photoUrl'] != null)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(75),
                          child: Image.network(
                            student['photoUrl']!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            student['name'][0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      student['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Details
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Roll Number', student['rollNumber']),
                    _buildDetailRow("Father's Name", student['fatherName']),
                    _buildDetailRow("Mother's Name", student['motherName']),
                    _buildDetailRow('Contact', student['contactNumber']),
                    if (student['bloodGroup'] != null)
                      _buildDetailRow('Blood Group', student['bloodGroup']!),
                    _buildDetailRow('Address', student['address']),
                  ],
                ),
              ),
              // Action
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001F3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF001F3F).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF001F3F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadSingleIDCard(
    BuildContext context,
    dynamic student,
    dynamic classModel,
    String backgroundUrl,
    String prefix,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      print(student['admissionNumber']);
      var imageBytes;
      if (prefix == 'ID-12') {
        imageBytes = await _generateIDCardImage(
          student,
          classModel,
          backgroundUrl!, // ✅ ASSET
        );
      } else if (prefix == 'ID-01') {
        imageBytes = await _generateIDCardImage1(
          student,
          classModel,
          backgroundUrl!, // ✅ ASSET
        );
      } else if (prefix == 'ID-02') {
        imageBytes = await _generateIDCardImage2(
          student,
          classModel,
          backgroundUrl!, // ✅ ASSET
        );
      }
      if (context.mounted) Navigator.pop(context);

      final safeName = student['name']
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');

      final blob = html.Blob([imageBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..download = '${safeName}_ID_Card.png'
        ..click();

      html.Url.revokeObjectUrl(url);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('ID card downloaded successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Error: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadAllIDCards(
    BuildContext context,
    List<Map<String, dynamic>> students,
    dynamic classModel,
    String backgroundUrl,
    String prefix,
  ) async {
    setState(() {
      _isGeneratingCards = true;
    });

    try {
      // Create archive
      final archive = Archive();

      // Generate ID card for each student
      for (var student in students) {
        var imageBytes;

        if (prefix == 'ID-12') {
          imageBytes = await _generateIDCardImage(
            student,
            classModel,
            backgroundUrl, // ✅ ASSET
          );
        } else if (prefix == 'ID-01') {
          imageBytes = await _generateIDCardImage1(
            student,
            classModel,
            backgroundUrl, // ✅ ASSET
          );
        } else if (prefix == 'ID-02') {
          imageBytes = await _generateIDCardImage2(
            student,
            classModel,
            backgroundUrl, // ✅ ASSET
          );
        }
        final safeName = student['name']
            .replaceAll(RegExp(r'[^\w\s-]'), '')
            .replaceAll(' ', '_');
        final fileName = '${safeName}_ID_Card.png';
        archive.addFile(ArchiveFile(fileName, imageBytes.length, imageBytes));
      }

      // Encode archive as ZIP
      final zipBytes = ZipEncoder().encode(archive);

      if (zipBytes != null) {
        // Download ZIP file on web
        final blob = html.Blob([zipBytes], 'application/zip');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final zipFileName =
            '${classModel.className.replaceAll(' ', '_')}_ID_Cards.zip';

        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', zipFileName)
          ..click();

        html.Url.revokeObjectUrl(url);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('${students.length} ID cards downloaded as ZIP'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Error: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isGeneratingCards = false;
      });
    }
  }

  /// Generates a single ID card image as PNG Uint8List given a student, classModel, and background URL.
  ///
  /// Loads the background image (asset/network) and the student photo (Firebase).
  /// Draws the student photo (center-crop, no stretching) and the student details.
  /// Returns the generated ID card image as PNG Uint8List.
  ///
  /// Throws a [FutureError] if an error occurs during image loading or drawing.
  ///

  Future<ui.Image?> loadNetworkImageWebSafe(String url) async {
    final completer = Completer<ui.Image>();

    final img = html.ImageElement()
      ..crossOrigin = 'anonymous'
      ..src = url;

    img.onLoad.listen((_) async {
      final canvas = html.CanvasElement(width: img.width!, height: img.height!);
      final ctx = canvas.context2D;
      ctx.drawImage(img, 0, 0);

      final dataUrl = canvas.toDataUrl();
      final bytes = Uri.parse(dataUrl).data!.contentAsBytes();

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      completer.complete(frame.image);
    });

    img.onError.listen((_) {
      completer.complete(null);
    });

    return completer.future;
  }

  Future<Uint8List> _generateIDCardImage(
    dynamic student,
    dynamic classModel,
    String backgroundUrl,
  ) async {
    // print(backgroundUrl);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const double cardWidth = 350;
    const double cardHeight = 550;

    // ✅ LOAD IMAGES CORRECTLY
    final bgImage = await loadNetworkImageWebSafe(backgroundUrl);

    ui.Image? photoImage;
    final photoUrl = student['photoUrl'];
    if (photoUrl != null && photoUrl.toString().isNotEmpty) {
      photoImage = await loadNetworkImageWebSafe(photoUrl);
    }

    final cardRect = Rect.fromLTWH(0, 0, cardWidth, cardHeight);
    canvas.clipRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(20)),
    );

    // BACKGROUND
    if (bgImage != null) {
      canvas.drawImageRect(
        bgImage,
        Rect.fromLTWH(
          0,
          0,
          bgImage.width.toDouble(),
          bgImage.height.toDouble(),
        ),
        cardRect,
        Paint()..filterQuality = ui.FilterQuality.high,
      );
    } else {
      canvas.drawRect(cardRect, Paint()..color = const Color(0xFFEFEFEF));
    }

    // TEXT HELPER
    void drawText(
      String text,
      double x, // NEW: horizontal position
      double y, // vertical position (TOP of text)
      double size,
      FontWeight weight,
      Color color, {
      TextAlign align = TextAlign.center, // NEW
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: GoogleFonts.poppins(
            fontSize: size,
            fontWeight: weight,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: align,
      )..layout(maxWidth: cardWidth - 20);

      double drawX = x;

      // Adjust X based on alignment
      if (align == TextAlign.center) {
        drawX = x - painter.width / 2;
      } else if (align == TextAlign.right) {
        drawX = x - painter.width;
      }

      painter.paint(canvas, Offset(drawX, y));
    }

    List<String> splitTextIntoLines(
      String text, {
      int maxCharsPerLine = 12,
      int maxLines = 3,
    }) {
      final words = text.trim().split(RegExp(r'\s+'));
      final lines = <String>[];
      String currentLine = '';

      for (final word in words) {
        final testLine = currentLine.isEmpty ? word : '$currentLine $word';

        if (testLine.length <= maxCharsPerLine) {
          currentLine = testLine;
        } else {
          if (currentLine.isNotEmpty) {
            lines.add(currentLine);
          }
          currentLine = word;

          if (lines.length == maxLines - 1) {
            lines.add('$currentLine...');
            return lines;
          }
        }
      }

      if (currentLine.isNotEmpty && lines.length < maxLines) {
        lines.add(currentLine);
      }

      return lines;
    }

    void drawBalancedText(
      String text,
      double x,
      double y,
      double size,
      FontWeight weight,
      Color color, {
      double lineGap = 3,
    }) {
      final lines = splitTextIntoLines(text, maxCharsPerLine: 12, maxLines: 3);

      for (int i = 0; i < lines.length; i++) {
        final painter = TextPainter(
          text: TextSpan(
            text: lines[i],
            style: GoogleFonts.poppins(
              fontSize: size,
              fontWeight: weight,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 200);

        painter.paint(canvas, Offset(x, y + i * (painter.height + lineGap)));
      }
    }

    // PHOTO RECT
    const double photoWidth = 140;
    const double photoHeight = 180;
    const double radius = 10;

    final photoRect = Rect.fromCenter(
      center: const Offset(cardWidth / 1.77, 238),
      width: photoWidth,
      height: photoHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        photoRect.inflate(4),
        const Radius.circular(radius + 4),
      ),
      Paint()..color = const ui.Color.fromARGB(0, 255, 255, 255),
    );

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(photoRect, const Radius.circular(radius)),
    );

    if (photoImage != null) {
      canvas.drawImageRect(
        photoImage,
        Rect.fromLTWH(
          0,
          0,
          photoImage.width.toDouble(),
          photoImage.height.toDouble(),
        ),
        photoRect,
        Paint()..filterQuality = ui.FilterQuality.high,
      );
    } else {
      canvas.drawRect(
        photoRect,
        Paint()..color = const ui.Color.fromARGB(0, 0, 0, 0).withOpacity(0.1),
      );
    }

    canvas.restore();

    // DETAILS
    double y = 340;
    drawText(
      student['name'] ?? '?'.toString().toUpperCase(),
      cardWidth / 1.75,
      329,
      24,
      FontWeight.w800,
      Colors.red,
    );
    drawText(
      'STD: ${(student['batch'] ?? '?').toString().toUpperCase()}',
      cardWidth / 1.75,
      356,
      18,
      FontWeight.w700,
      Colors.black,
    );

    drawText(
      'Ad.No: ${student['admissionNumber'] ?? '?'.toString().toUpperCase()}     Dob: ${student['dateOfBirth'] ?? '?'.toString().toUpperCase()}',
      cardWidth / 1.75,
      391,
      16,
      FontWeight.w700,
      Colors.blue,
    );
    final address = student['address'] ?? '?';
    drawBalancedText(
      address,
      cardWidth / 5,
      420,
      16,
      FontWeight.w600,
      Colors.black,
    );

    drawText(
      'Ph:${student['contactNumber'] ?? '?'.toString().toUpperCase()},${student['phoneNumber'] ?? '?'.toString().toUpperCase()}',
      cardWidth / 2,
      510,
      16,
      FontWeight.w700,
      Colors.red,
    );
    y += 42;

    final picture = recorder.endRecording();
    final image = await picture.toImage(cardWidth.toInt(), cardHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _generateIDCardImage1(
    dynamic student,
    dynamic classModel,
    String backgroundUrl,
  ) async {
    // print(backgroundUrl);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const double cardWidth = 350;
    const double cardHeight = 550;

    // ✅ LOAD IMAGES CORRECTLY
    final bgImage = await loadNetworkImageWebSafe(backgroundUrl);

    ui.Image? photoImage;
    final photoUrl = student['photoUrl'];
    if (photoUrl != null && photoUrl.toString().isNotEmpty) {
      photoImage = await loadNetworkImageWebSafe(photoUrl);
    }

    final cardRect = Rect.fromLTWH(0, 0, cardWidth, cardHeight);
    canvas.clipRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(20)),
    );

    // BACKGROUND
    if (bgImage != null) {
      canvas.drawImageRect(
        bgImage,
        Rect.fromLTWH(
          0,
          0,
          bgImage.width.toDouble(),
          bgImage.height.toDouble(),
        ),
        cardRect,
        Paint()..filterQuality = ui.FilterQuality.high,
      );
    } else {
      canvas.drawRect(cardRect, Paint()..color = const Color(0xFFEFEFEF));
    }

    // TEXT HELPER
    void drawText(
      String text,
      double x,
      double y,
      double size,
      FontWeight weight,
      Color color, {
      double maxWidth = 200, // control width
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: size, fontWeight: weight, color: color),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left, // 👈 always left
      )..layout(maxWidth: maxWidth);

      // 👇 FIXED START POSITION (NO SHIFTING)
      painter.paint(canvas, Offset(x, y));
    }

    List<String> splitTextIntoLinesSmart(
      String text, {
      int maxLines = 3,
      int minCharsPerLine = 9,
    }) {
      final words = text.trim().split(RegExp(r'\s+'));
      final totalWords = words.length;

      if (totalWords == 0) return [];

      // Decide number of lines
      int lines = (totalWords / 3).ceil(); // prefer 3 words per line
      lines = lines.clamp(1, maxLines);

      // Distribute words evenly
      int wordsPerLine = (totalWords / lines).ceil();

      List<List<String>> result = [];
      int index = 0;

      for (int i = 0; i < lines; i++) {
        int remainingWords = totalWords - index;
        int remainingLines = lines - i;

        int take = (remainingWords / remainingLines).ceil();
        take = take.clamp(2, 3); // enforce 2–3 words per line

        result.add(words.sublist(index, (index + take).clamp(0, totalWords)));
        index += take;

        if (index >= totalWords) break;
      }

      // 🔥 Adjust for minimum characters
      for (int i = 0; i < result.length - 1; i++) {
        String current = result[i].join(' ');
        if (current.length < minCharsPerLine && result[i + 1].isNotEmpty) {
          result[i].add(result[i + 1].removeAt(0));
        }
      }

      return result.map((e) => e.join(' ')).toList();
    }

    void drawTextHeading(
      String text,
      double x, // NEW: horizontal position
      double y, // vertical position (TOP of text)
      double size,
      FontWeight weight,
      Color color, {
      TextAlign align = TextAlign.center, // NEW
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: size,
            fontWeight: weight,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: align,
      )..layout(maxWidth: cardWidth - 20);

      double drawX = x;

      // Adjust X based on alignment
      if (align == TextAlign.center) {
        drawX = x - painter.width / 2;
      } else if (align == TextAlign.right) {
        drawX = x - painter.width;
      }

      painter.paint(canvas, Offset(drawX, y));
    }

    void drawBalancedText(
      String text,
      double x,
      double y,
      double size,
      FontWeight weight,
      Color color, {
      double lineGap = 2,
    }) {
      final lines = splitTextIntoLinesSmart(text);
      for (int i = 0; i < lines.length; i++) {
        final painter = TextPainter(
          text: TextSpan(
            text: lines[i],
            style: TextStyle(fontSize: size, fontWeight: weight, color: color),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 300);

        painter.paint(canvas, Offset(x, y + i * (painter.height + lineGap)));
      }
    }

    // PHOTO RECT
    const double photoWidth = 132;
    const double photoHeight = 152;
    const double radius = 1;

    final photoRect = Rect.fromCenter(
      center: const Offset(cardWidth / 2.01, 185),
      width: photoWidth,
      height: photoHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        photoRect.inflate(4),
        const Radius.circular(radius + 4),
      ),
      Paint()..color = const ui.Color.fromARGB(0, 255, 255, 255),
    );

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(photoRect, const Radius.circular(radius)),
    );

    if (photoImage != null) {
      canvas.drawImageRect(
        photoImage,
        Rect.fromLTWH(
          0,
          0,
          photoImage.width.toDouble(),
          photoImage.height.toDouble(),
        ),
        photoRect,
        Paint()..filterQuality = ui.FilterQuality.high,
      );
    } else {
      canvas.drawRect(
        photoRect,
        Paint()..color = const ui.Color.fromARGB(0, 0, 0, 0).withOpacity(0.1),
      );
    }

    canvas.restore();

    // DETAILS
    double y = 340;
    drawTextHeading(
      student['bloodGroup'] ?? '?',
      cardWidth / 1.11,
      165.5,
      18,
      FontWeight.w800,
      Colors.red,
    );
    drawTextHeading(
      student['name'] ?? '?',
      cardWidth / 2,
      265,
      24,
      FontWeight.w800,
      Colors.black,
    );
    drawTextHeading(
      'CLASS: ${(student['batch'] ?? '?').toString().toUpperCase()}',
      cardWidth / 2,
      300,
      18,
      FontWeight.w700,
      Colors.black,
    );

    drawText(
      'Admn No: ${student['admissionNumber'] ?? '?'.toString().toUpperCase()}',
      30,
      344,
      16,
      FontWeight.w500,
      Colors.black,
    );
    drawText(
      'DOB: ${student['dateOfBirth'] ?? '?'.toString().toUpperCase()}',
      30,
      369,
      16,
      FontWeight.w500,
      Colors.black,
    );

    final address = student['address'] ?? '?';
    drawBalancedText(address, 30, 393, 16, FontWeight.w500, Colors.black);

    drawText(
      'Contact: ${student['contactNumber'] ?? '?'.toString().toUpperCase()}',
      30,
      458,
      16,
      FontWeight.w500,
      const ui.Color.fromARGB(255, 0, 0, 0),
    );
    y += 42;

    final picture = recorder.endRecording();
    final image = await picture.toImage(cardWidth.toInt(), cardHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _generateIDCardImage2(
    dynamic student,
    dynamic classModel,
    String backgroundUrl,
  ) async {
    // print(backgroundUrl);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const double cardWidth = 350;
    const double cardHeight = 550;

    // ✅ LOAD IMAGES CORRECTLY
    final bgImage = await loadNetworkImageWebSafe(backgroundUrl);

    ui.Image? photoImage;
    final photoUrl = student['photoUrl'];
    if (photoUrl != null && photoUrl.toString().isNotEmpty) {
      photoImage = await loadNetworkImageWebSafe(photoUrl);
    }

    final cardRect = Rect.fromLTWH(0, 0, cardWidth, cardHeight);
    canvas.clipRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(20)),
    );

    // BACKGROUND
    if (bgImage != null) {
      canvas.drawImageRect(
        bgImage,
        Rect.fromLTWH(
          0,
          0,
          bgImage.width.toDouble(),
          bgImage.height.toDouble(),
        ),
        cardRect,
        Paint()..filterQuality = ui.FilterQuality.high,
      );
    } else {
      canvas.drawRect(cardRect, Paint()..color = const Color(0xFFEFEFEF));
    }
    List<String> splitTextIntoLinesSmart(
      String text, {
      int maxLines = 3,
      int minCharsPerLine = 9,
    }) {
      final words = text.trim().split(RegExp(r'\s+'));
      final totalWords = words.length;

      if (totalWords == 0) return [];

      // Decide number of lines
      int lines = (totalWords / 3).ceil(); // prefer 3 words per line
      lines = lines.clamp(1, maxLines);

      // Distribute words evenly
      int wordsPerLine = (totalWords / lines).ceil();

      List<List<String>> result = [];
      int index = 0;

      for (int i = 0; i < lines; i++) {
        int remainingWords = totalWords - index;
        int remainingLines = lines - i;

        int take = (remainingWords / remainingLines).ceil();
        take = take.clamp(2, 3); // enforce 2–3 words per line

        result.add(words.sublist(index, (index + take).clamp(0, totalWords)));
        index += take;

        if (index >= totalWords) break;
      }

      // 🔥 Adjust for minimum characters
      for (int i = 0; i < result.length - 1; i++) {
        String current = result[i].join(' ');
        if (current.length < minCharsPerLine && result[i + 1].isNotEmpty) {
          result[i].add(result[i + 1].removeAt(0));
        }
      }

      return result.map((e) => e.join(' ')).toList();
    }

    void drawTextHeading(
      String text,
      double x, // NEW: horizontal position
      double y, // vertical position (TOP of text)
      double size,
      FontWeight weight,
      Color color, {
      TextAlign align = TextAlign.center, // NEW
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: size,
            fontWeight: weight,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: align,
      )..layout(maxWidth: cardWidth - 20);

      double drawX = x;

      // Adjust X based on alignment
      if (align == TextAlign.center) {
        drawX = x - painter.width / 2;
      } else if (align == TextAlign.right) {
        drawX = x - painter.width;
      }

      painter.paint(canvas, Offset(drawX, y));
    }

    void drawBalancedText(
      String text,
      double x,
      double y,
      double size,
      FontWeight weight,
      Color color, {
      double lineGap = 2,
    }) {
      final lines = splitTextIntoLinesSmart(text);
      for (int i = 0; i < lines.length; i++) {
        final painter = TextPainter(
          text: TextSpan(
            text: lines[i],
            style: TextStyle(fontSize: size, fontWeight: weight, color: color),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 300);

        painter.paint(canvas, Offset(x, y + i * (painter.height + lineGap)));
      }
    }

    // TEXT HELPER
    void drawText(
      String text,
      double x,
      double y,
      double size,
      FontWeight weight,
      Color color,
    ) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: size, fontWeight: weight, color: color),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1, // 👈 prevents wrapping
      )..layout(); // no width limit

      painter.paint(canvas, Offset(x, y));
    }

    void drawTextStroke(
      Canvas canvas,
      String text,
      double centerX, // 👈 pass center X instead of left X
      double y,
      double size,
      FontWeight weight,
      Color color,
    ) {
      final textStyle = TextStyle(fontSize: size, fontWeight: weight);

      // 🔹 Measure text width
      final measurePainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      final textWidth = measurePainter.width;

      // 👇 Calculate starting X so text is centered
      final startX = centerX - (textWidth / 2);

      // 🔸 Stroke (border)
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFFFFFF)
        ..strokeJoin = StrokeJoin.round;

      final strokePainter = TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(foreground: strokePaint),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      strokePainter.paint(canvas, Offset(startX, y));

      // 🔸 Fill (text)
      final fillPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(color: color),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      fillPainter.paint(canvas, Offset(startX, y));
    }

    List<String> splitTextIntoLines(
      String text, {
      int maxCharsPerLine = 12,
      int maxLines = 3,
    }) {
      final words = text.trim().split(RegExp(r'\s+'));
      final lines = <String>[];
      String currentLine = '';

      for (final word in words) {
        final testLine = currentLine.isEmpty ? word : '$currentLine $word';

        if (testLine.length <= maxCharsPerLine) {
          currentLine = testLine;
        } else {
          if (currentLine.isNotEmpty) {
            lines.add(currentLine);
          }
          currentLine = word;

          if (lines.length == maxLines - 1) {
            lines.add('$currentLine...');
            return lines;
          }
        }
      }

      if (currentLine.isNotEmpty && lines.length < maxLines) {
        lines.add(currentLine);
      }

      return lines;
    }

    // void drawBalancedText(
    //   String text,
    //   double x,
    //   double y,
    //   double size,
    //   FontWeight weight,
    //   Color color, {
    //   double lineGap = 3,
    // }) {
    //   final lines = splitTextIntoLines(text, maxCharsPerLine: 20, maxLines: 3);

    //   for (int i = 0; i < lines.length; i++) {
    //     final painter = TextPainter(
    //       text: TextSpan(
    //         text: lines[i],
    //         style: GoogleFonts.poppins(
    //           fontSize: size,
    //           fontWeight: weight,
    //           color: color,
    //         ),
    //       ),
    //       textDirection: TextDirection.ltr,
    //     )..layout(maxWidth: 200);

    //     painter.paint(canvas, Offset(x, y + i * (painter.height + lineGap)));
    //   }
    // }

    // PHOTO RECT
    const double photoWidth = 156;
    const double photoHeight = 190.5;
    const double radius = 1;

    final photoRect = Rect.fromCenter(
      center: const Offset(cardWidth / 2, 234.5),
      width: photoWidth,
      height: photoHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        photoRect.inflate(4),
        const Radius.circular(radius + 4),
      ),
      Paint()..color = const ui.Color.fromARGB(0, 255, 255, 255),
    );

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(photoRect, const Radius.circular(radius)),
    );

    if (photoImage != null) {
      canvas.drawImageRect(
        photoImage,
        Rect.fromLTWH(
          0,
          0,
          photoImage.width.toDouble(),
          photoImage.height.toDouble(),
        ),
        photoRect,
        Paint()..filterQuality = ui.FilterQuality.high,
      );
    } else {
      canvas.drawRect(
        photoRect,
        Paint()..color = const ui.Color.fromARGB(0, 0, 0, 0).withOpacity(0.1),
      );
    }

    canvas.restore();

    // DETAILS
    double y = 340;
    // drawText(
    //   '${student['bloodGroup'] ?? '?'.toString().toUpperCase()}',
    //   cardWidth / 1.11,
    //   165.5,
    //   18,
    //   FontWeight.w800,
    //   Colors.red,
    // );
    drawTextHeading(
      student['name'] ?? '?'.toString().toUpperCase(),
      cardWidth / 2,
      340,
      25,
      FontWeight.w800,
      Colors.red,
    );
    drawTextHeading(
      'STD: ${(student['batch'] ?? '?').toString().toUpperCase()}',
      cardWidth / 2,
      370,
      20,
      FontWeight.w700,
      Colors.black,
    );

    drawText(
      'Ad.No: ${student['admissionNumber'] ?? '?'.toString().toUpperCase()}',
      30,
      400,
      18,
      FontWeight.w700,
      const ui.Color.fromARGB(255, 33, 79, 243),
    );
    drawText(
      'Dob: ${student['dateOfBirth'] ?? '?'.toString().toUpperCase()}',
      cardWidth / 2,
      400,
      18,
      FontWeight.w700,
      const ui.Color.fromARGB(255, 33, 79, 243),
    );
    final address1 = student['address1'] ?? '?';
    final address2 = student['address2'] ?? '?';
    final address3 = student['address3'] ?? '?';

    drawBalancedText(address1, 30, 427, 18, FontWeight.w500, Colors.black);
    drawBalancedText(address2, 30, 447, 18, FontWeight.w500, Colors.black);
    drawBalancedText(address3, 30, 467, 18, FontWeight.w500, Colors.black);

    drawTextStroke(
      canvas,
      'Ph: ${student['contactNumber'] ?? '?'.toString().toUpperCase()} - ${student['phoneNumber'] ?? '?'.toString().toUpperCase()}',
      cardWidth / 2,
      520,
      16,
      FontWeight.w700,
      const ui.Color.fromARGB(255, 0, 0, 0),
    );
    y += 42;

    final picture = recorder.endRecording();
    final image = await picture.toImage(cardWidth.toInt(), cardHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void _confirmDelete(BuildContext context, dynamic student) {
    // Only allow delete for non-demo students
    if (student['id'].toString().startsWith('demo')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Cannot delete demo students'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Confirm Delete'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${student['name']}? This action cannot be undone.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final success = await context
                  .read<StudentProvider>()
                  .deleteStudent(
                    widget.schoolId,
                    widget.classId,
                    student['id'],
                  );
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Student deleted successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _exportStudentData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Data export feature coming soon'),
          ],
        ),
        backgroundColor: const Color(0xFF001F3F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
