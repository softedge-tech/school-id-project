import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import '../../models.dart';

class StudentEditScreen extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String studentId;

  const StudentEditScreen({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.studentId,
  });

  @override
  State<StudentEditScreen> createState() => _StudentEditScreenState();
}

class _StudentEditScreenState extends State<StudentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _fatherController = TextEditingController();
  final _motherController = TextEditingController();
  final _addressController1 = TextEditingController();
  final _addressController2 = TextEditingController();
  final _addressController3 = TextEditingController();
  final _contactController = TextEditingController();
  final _bloodGroupController = TextEditingController();

  Student? _student;
  bool _isLoading = true;
  bool _isSaving = false;

  // Photo state
  Uint8List? _processedPhotoBytes; // compressed JPEG ready to upload
  bool _isProcessingPhoto = false;
  String _photoStatus = '';

  // Firestore reference shorthand
  DocumentReference get _studentDoc => FirebaseFirestore.instance
      .collection('schools')
      .doc(widget.schoolId)
      .collection('classes')
      .doc(widget.classId)
      .collection('students')
      .doc(widget.studentId);

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _fatherController.dispose();
    _motherController.dispose();
    _addressController1.dispose();
    _addressController2.dispose();
    _addressController3.dispose();
    _contactController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }

  // ── Load ─────────────────────────────────────────────────────

  Future<void> _loadStudent() async {
    try {
      final doc = await _studentDoc.get();
      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _student = Student.fromMap(data, doc.id);
          _nameController.text = data['name'] ?? '';
          _rollController.text = data['rollNumber'] ?? '';
          _fatherController.text = data['fatherName'] ?? '';
          _motherController.text = data['motherName'] ?? '';
          _addressController1.text = data['address1'] ?? '';
          _addressController2.text = data['address2'] ?? '';
          _addressController3.text = data['address3'] ?? '';
          _contactController.text = data['contactNumber'] ?? '';
          _bloodGroupController.text = data['bloodGroup'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load student: $e', isError: true);
      }
    }
  }

  // ── Image helpers ─────────────────────────────────────────────

  /// Compress on a background isolate: resize to max 1024 px on the longer
  /// side, then encode as JPEG at 85 % quality to reduce file size.
  static Uint8List _compressImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    const maxDim = 1024;
    final img.Image resized;
    if (image.width >= image.height && image.width > maxDim) {
      resized = img.copyResize(image, width: maxDim);
    } else if (image.height > image.width && image.height > maxDim) {
      resized = img.copyResize(image, height: maxDim);
    } else {
      resized = image; // already small enough
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  Future<void> _pickAndProcessImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return;

    setState(() {
      _isProcessingPhoto = true;
      _photoStatus = 'Compressing photo…';
      _processedPhotoBytes = null;
    });

    try {
      final bytes = await file.readAsBytes();
      final compressed = await compute(_compressImage, bytes);
      if (mounted) {
        setState(() {
          _processedPhotoBytes = compressed;
          _photoStatus = 'Photo ready ✓';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _photoStatus = '');
        _showSnack('Image processing failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessingPhoto = false);
    }
  }

  // ── Upload photo to Firebase Storage ─────────────────────────

  Future<String> _uploadPhoto() async {
    final ref = FirebaseStorage.instance.ref().child(
      'students/${widget.schoolId}/${widget.classId}/${widget.studentId}'
      '/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final task = await ref.putData(
      _processedPhotoBytes!,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  // ── Save to Firestore ─────────────────────────────────────────

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Changes'),
        content: const Text('Save these changes to the student record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      // Step 1 — upload new photo if available
      String? newPhotoUrl;
      if (_processedPhotoBytes != null) {
        newPhotoUrl = await _uploadPhoto();
      }

      // Step 2 — build update payload
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'rollNumber': _rollController.text.trim(),
        'fatherName': _fatherController.text.trim(),
        'motherName': _motherController.text.trim(),
        'address1': _addressController1.text.trim(),
        'address2': _addressController2.text.trim(),
        'address3': _addressController3.text.trim(),
        'contactNumber': _contactController.text.trim(),
        'bloodGroup': _bloodGroupController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (newPhotoUrl != null) 'photoUrl': newPhotoUrl,
      };

      // Step 3 — write to Firestore
      await _studentDoc.update(updateData);

      if (mounted) {
        _showSnack('Student updated successfully');
        context.pop();
      }
    } catch (e) {
      _showSnack('Save failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Snack helper ──────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Not Found')),
        body: const Center(child: Text('Student not found')),
      );
    }

    final busy = _isSaving || _isProcessingPhoto;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Student'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: busy ? null : _saveChanges,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photo Section ──────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: busy ? null : _pickAndProcessImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Avatar
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade100,
                              border: Border.all(
                                color: _processedPhotoBytes != null
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade300,
                                width: _processedPhotoBytes != null ? 2.5 : 1.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _processedPhotoBytes != null
                                ? Image.memory(
                                    _processedPhotoBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : (_student!.photoUrl != null
                                      ? Image.network(
                                          _student!.photoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.person,
                                                size: 60,
                                              ),
                                        )
                                      : const Icon(Icons.person, size: 60)),
                          ),

                          // Processing overlay
                          if (_isProcessingPhoto)
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.55),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Compressing…',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Saving dim
                          if (_isSaving)
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.25),
                              ),
                            ),

                          // Camera badge
                          if (!busy)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Status label
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _photoStatus.isNotEmpty
                          ? Text(
                              _photoStatus,
                              key: ValueKey(_photoStatus),
                              style: TextStyle(
                                fontSize: 12,
                                color: _photoStatus.contains('✓')
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : Text(
                              'Tap to change photo',
                              key: const ValueKey('hint'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Form Fields ────────────────────────────────────
              _field(
                _nameController,
                'Student Name',
                Icons.person,
                required: true,
              ),
              _field(
                _rollController,
                'Roll Number',
                Icons.numbers,
                required: true,
              ),
              _field(
                _fatherController,
                "Father's Name",
                Icons.person_outline,
                required: true,
              ),
              _field(
                _motherController,
                "Mother's Name",
                Icons.person_outline,
                required: true,
              ),
              _field(
                _contactController,
                'Contact Number',
                Icons.phone,
                required: true,
                keyboard: TextInputType.phone,
              ),
              _field(_bloodGroupController, 'Blood Group', Icons.bloodtype),
              _field(
                _addressController1,
                'Address Line 1',
                Icons.home,
                required: true,
                maxLines: 2,
              ),
              _field(
                _addressController2,
                'Address Line 2',
                Icons.home,
                required: true,
                maxLines: 2,
              ),
              _field(
                _addressController3,
                'Address Line 3',
                Icons.home,
                required: true,
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              // ── Save Button ────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: busy ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Field builder ─────────────────────────────────────────────

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}