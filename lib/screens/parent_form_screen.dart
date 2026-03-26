import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ParentFormScreen extends StatefulWidget {
  final String schoolId;
  final String classId;

  const ParentFormScreen({
    super.key,
    required this.schoolId,
    required this.classId,
  });

  @override
  State<ParentFormScreen> createState() => _ParentFormScreenState();
}

class _ParentFormScreenState extends State<ParentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _fatherController = TextEditingController();
  final _boardingController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _batchController = TextEditingController();
  final _dobController = TextEditingController();
  final _admissionNumberController = TextEditingController();

  Uint8List? _photoBytes;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  // ── Server state ─────────────────────────────────────────────
  bool _isServerWaking = true;
  bool _serverReady = false;
  bool _serverFailed = false;
  String _wakeUpStatus = 'Connecting to server...';
  // ────────────────────────────────────────────────────────────

  static const String _serverUrl = 'https://rembg-api-an5m.onrender.com';

  @override
  void initState() {
    super.initState();
    _wakeUpServer();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _fatherController.dispose();
    _boardingController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _phoneNumberController.dispose();
    _bloodGroupController.dispose();
    _batchController.dispose();
    _dobController.dispose();
    _admissionNumberController.dispose();
    super.dispose();
  }

  // ── Wake up server with 10 retries ──────────────────────────
  Future<void> _wakeUpServer() async {
    if (mounted) {
      setState(() {
        _isServerWaking = true;
        _serverReady = false;
        _serverFailed = false;
        _wakeUpStatus = 'Connecting to server...';
      });
    }

    for (int attempt = 1; attempt <= 10; attempt++) {
      try {
        if (mounted) {
          setState(() {
            _wakeUpStatus = attempt == 1
                ? 'Starting up server...'
                : 'Still warming up... ($attempt/10)';
          });
        }

        debugPrint('🔄 Wake-up attempt $attempt...');

        final response = await http
            .get(Uri.parse('$_serverUrl/health'))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          debugPrint('✅ Server is awake!');
          if (mounted) {
            setState(() {
              _serverReady = true;
              _isServerWaking = false;
              _serverFailed = false;
              _wakeUpStatus = 'Server is ready!';
            });
          }
          // Warm up model in background while user fills form
          _warmUpModel();
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Attempt $attempt failed: $e');
        if (attempt < 10) {
          await Future.delayed(const Duration(seconds: 5));
        }
      }
    }

    debugPrint('❌ Server wake-up failed after 10 attempts');
    if (mounted) {
      setState(() {
        _serverFailed = true;
        _isServerWaking = false;
        _serverReady = false;
        _wakeUpStatus = 'Could not connect to server';
      });
    }
  }

  // ── Send tiny image to trigger model loading in background ───
  Future<void> _warmUpModel() async {
    try {
      debugPrint('🔥 Warming up model...');
      final tinyImage = base64Decode(
        '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8U'
        'HRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgN'
        'DRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIy'
        'MjL/wAARCAABAAEDASIAAhEBAxEB/8QAFgABAQEAAAAAAAAAAAAAAAAABgUE/8QAIhAAAQME'
        'AgMAAAAAAAAAAAAAAQIDBAUREiExQf/EABQBAQAAAAAAAAAAAAAAAAAAAAD/xAAUEQEAAAAA'
        'AAAAAAAAAAAAAP/aAAwDAQACEQMRAD8Aq2tqaW3RS0FLFTxLuWOJgaM+cADJPuSeSepJ6k'
        'k96KKAf//Z',
      );

      final request =
          http.MultipartRequest('POST', Uri.parse('$_serverUrl/remove-bg'))
            ..files.add(
              http.MultipartFile.fromBytes(
                'image',
                tinyImage,
                filename: 'warmup.jpg',
                contentType: MediaType('image', 'jpeg'),
              ),
            );

      await request.send().timeout(const Duration(seconds: 90));
      debugPrint('🔥 Model warmed up!');
    } catch (e) {
      debugPrint('⚠️ Warm-up ping failed (ok): $e');
    }
  }
  // ────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _photoBytes = bytes);
    }
  }

  // ── Resize image before sending to save server RAM ──────────
  static Uint8List _resizeImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    if (image.width <= 800 && image.height <= 800) return bytes;

    final resized = image.width > image.height
        ? img.copyResize(image, width: 800)
        : img.copyResize(image, height: 800);

    return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
  }
  // ────────────────────────────────────────────────────────────

  Future<Uint8List> _removeBackground(Uint8List imageBytes) async {
    debugPrint('🎨 Sending image to rembg server...');

    final resizedBytes = await compute(_resizeImage, imageBytes);
    debugPrint('📦 Resized: ${resizedBytes.length} bytes');

    http.Response response;

    // ✅ WEB → use base64 JSON (MOST RELIABLE)
    if (kIsWeb) {
      response = await http
          .post(
            Uri.parse('$_serverUrl/remove-bg'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image': base64Encode(resizedBytes)}),
          )
          .timeout(const Duration(seconds: 120));
    }
    // ✅ MOBILE → use multipart (BEST FOR FILES)
    else {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/remove-bg'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          resizedBytes,
          filename: 'photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );

      response = await http.Response.fromStream(streamedResponse);
    }

    if (response.statusCode == 200) {
      debugPrint('✅ Background removed successfully');
      return response.bodyBytes;
    } else {
      debugPrint('❌ Error: ${response.statusCode} ${response.body}');
      throw Exception('Server error (${response.statusCode})');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;

      final studentRef = firestore
          .collection('schools')
          .doc(widget.schoolId)
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc();

      final studentId = studentRef.id;

      // ── Step 1: Remove background — STOP if fails ────────────
      Uint8List processedBytes;
      try {
        processedBytes = await _removeBackground(_photoBytes!);
      } catch (e) {
        debugPrint('❌ BG removal failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Background removal failed. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() => _isSubmitting = false);
        }
        return; // ← STOP here, don't upload anything
      }
      // ────────────────────────────────────────────────────────

      // ── Step 2: Upload to Firebase Storage ──────────────────
      final storageRef = storage.ref().child(
        'students/${widget.schoolId}/${widget.classId}/$studentId/${DateTime.now().millisecondsSinceEpoch}.png',
      );

      final uploadTask = await storageRef.putData(
        processedBytes,
        SettableMetadata(contentType: 'image/png'),
      );

      final photoUrl = await uploadTask.ref.getDownloadURL();
      // ────────────────────────────────────────────────────────

      // ── Step 3: Save to Firestore ────────────────────────────
      await studentRef.set({
        'schoolId': widget.schoolId,
        'classId': widget.classId,
        'name': _nameController.text.trim(),
        'rollNumber': _rollController.text.trim(),
        'fatherName': _fatherController.text.trim(),
        'motherName': _boardingController.text.trim(),
        'address': _addressController.text.trim(),
        'contactNumber': _contactController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'bloodGroup': _bloodGroupController.text.trim(),
        'batch': _batchController.text.trim(),
        'admissionNumber': _admissionNumberController.text.trim(),
        'dob': _dobController.text.trim(),
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
      });
      // ────────────────────────────────────────────────────────

      setState(() => _isSubmitted = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildWakeUpScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isServerWaking) ...[
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Please wait...',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _wakeUpStatus,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const SizedBox(width: 200, child: LinearProgressIndicator()),
                const SizedBox(height: 16),
                const Text(
                  'Server is starting up.\nThis takes up to 30 seconds\non first load.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ] else if (_serverFailed) ...[
                const Icon(Icons.cloud_off, size: 60, color: Colors.red),
                const SizedBox(height: 32),
                const Text(
                  'Connection Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Could not connect to the server.\nPlease check your internet\nconnection and try again.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _wakeUpServer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isServerWaking || _serverFailed) {
      return _buildWakeUpScreen();
    }

    if (_isSubmitted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Successfully Submitted!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Student details have been submitted.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isSubmitted = false;
                    _formKey.currentState?.reset();
                    _nameController.clear();
                    _rollController.clear();
                    _fatherController.clear();
                    _boardingController.clear();
                    _addressController.clear();
                    _contactController.clear();
                    _bloodGroupController.clear();
                    _batchController.clear();
                    _admissionNumberController.clear();
                    _dobController.clear();
                    _phoneNumberController.clear();
                    _photoBytes = null;
                  });
                },
                child: const Text('Submit Another'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student ID Card Form'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 10, color: Colors.green),
                const SizedBox(width: 4),
                const Text(
                  'Server Ready',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
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
              const Text(
                'Please fill in your child\'s details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'All fields are required',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _isSubmitting ? null : _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                      image: _photoBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_photoBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _photoBytes == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Upload Photo',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rollController,
                decoration: const InputDecoration(
                  labelText: 'Roll Number',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fatherController,
                decoration: const InputDecoration(
                  labelText: "Father's Name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _boardingController,
                decoration: const InputDecoration(
                  labelText: 'Boarding Point',
                  prefixIcon: Icon(Icons.directions_bus),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_android),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bloodGroupController,
                decoration: const InputDecoration(
                  labelText: 'Blood Group (Optional)',
                  prefixIcon: Icon(Icons.bloodtype),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _batchController,
                decoration: const InputDecoration(
                  labelText: 'Batch (XI-XII)',
                  prefixIcon: Icon(Icons.school),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _admissionNumberController,
                decoration: const InputDecoration(
                  labelText: 'Admission Number',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.cake),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 3,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Removing background & uploading...'),
                        ],
                      )
                    : const Text('Submit', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
