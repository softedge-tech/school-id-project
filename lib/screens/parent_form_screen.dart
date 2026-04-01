import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

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
  String _submitStatus = '';

  // ── remove.bg API key (free tier: 50 calls/month) ────────────
  // Get your free key at: https://www.remove.bg/dashboard#api-key
  static const String _removeBgApiKey = 'JN8MSbSLnCZVgaLe4HnX9Noh';
  // ────────────────────────────────────────────────────────────

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

  // ── Resize image before upload to reduce API payload ────────
  static Uint8List _resizeImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    if (image.width <= 800 && image.height <= 800) return bytes;
    final resized = image.width > image.height
        ? img.copyResize(image, width: 800)
        : img.copyResize(image, height: 800);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
  }

  // ── Call remove.bg free API to strip background ──────────────
  // Returns a transparent PNG as bytes.
  // Free tier returns 625×400 preview; upgrade for full resolution.
  Future<Uint8List> _removeBackground(Uint8List imageBytes) async {
    debugPrint('🎨 Sending image to remove.bg...');
    final resizedBytes = await compute(_resizeImage, imageBytes);
    debugPrint('📦 Resized: ${resizedBytes.length} bytes');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.remove.bg/v1.0/removebg'),
    );

    request.headers['X-Api-Key'] = _removeBgApiKey;
    request.fields['size'] = 'auto'; // use 'preview' on free plan
    request.fields['format'] = 'png'; // must be PNG for transparency

    request.files.add(
      http.MultipartFile.fromBytes(
        'image_file',
        resizedBytes,
        filename: 'photo.jpg',
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      debugPrint('✅ Background removed successfully');
      return response.bodyBytes; // transparent PNG
    } else {
      final body = jsonDecode(response.body);
      final msg = (body['errors'] as List?)?.first?['title'] ?? 'Unknown error';
      debugPrint('❌ remove.bg error: ${response.statusCode} — $msg');
      throw Exception('remove.bg: $msg');
    }
  }

  // ── Composite transparent PNG onto a solid blue background ───
  // Blue used: #0046A0 — standard ID-card royal blue
  static Uint8List _addBlueBackground(Uint8List transparentPngBytes) {
    final fg = img.decodeImage(transparentPngBytes);
    if (fg == null) return transparentPngBytes;

    // Create solid-blue canvas same size as foreground
    final bg = img.Image(width: fg.width, height: fg.height, numChannels: 4);

    // Royal blue: R=0, G=70, B=160
    img.fill(bg, color: img.ColorRgba8(0, 70, 160, 255));

    // Blend transparent foreground over blue background
    img.compositeImage(bg, fg, blend: img.BlendMode.alpha);

    return Uint8List.fromList(img.encodePng(bg));
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

    setState(() {
      _isSubmitting = true;
      _submitStatus = 'Removing background...';
    });

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

      // ── Step 1: Remove background ────────────────────────────
      Uint8List transparentBytes;
      try {
        transparentBytes = await _removeBackground(_photoBytes!);
      } catch (e) {
        debugPrint('❌ BG removal failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Background removal failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }

      // ── Step 2: Fill blue background ─────────────────────────
      setState(() => _submitStatus = 'Adding blue background...');
      final blueBytes = await compute(_addBlueBackground, transparentBytes);
      debugPrint('🔵 Blue background applied (${blueBytes.length} bytes)');

      // ── Step 3: Upload PNG to Firebase Storage ───────────────
      setState(() => _submitStatus = 'Uploading photo...');
      final storageRef = storage.ref().child(
        'students/${widget.schoolId}/${widget.classId}/$studentId'
        '/${DateTime.now().millisecondsSinceEpoch}.png',
      );

      final uploadTask = await storageRef.putData(
        blueBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      final photoUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('☁️ Uploaded: $photoUrl');

      // ── Step 4: Save student doc to Firestore ────────────────
      setState(() => _submitStatus = 'Saving student data...');
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

      setState(() => _isSubmitted = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Student added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitStatus = '';
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _isSubmitted = false;
      _formKey.currentState?.reset();
      for (final c in [
        _nameController,
        _rollController,
        _fatherController,
        _boardingController,
        _addressController,
        _contactController,
        _phoneNumberController,
        _bloodGroupController,
        _batchController,
        _dobController,
        _admissionNumberController,
      ]) {
        c.clear();
      }
      _photoBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Success screen ───────────────────────────────────────
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
                onPressed: _resetForm,
                child: const Text('Submit Another'),
              ),
            ],
          ),
        ),
      );
    }

    // ── Main form ────────────────────────────────────────────
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student ID Card Form'),
        backgroundColor: const Color(0xFF0046A0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Please fill in your child's details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fields marked * are required',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // ── Photo picker ─────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isSubmitting ? null : _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF0046A0),
                            width: 2,
                          ),
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
                    const SizedBox(height: 8),
                    const Text(
                      '🔵 Background will be replaced with blue',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0046A0),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Form fields ──────────────────────────────────
              _field(
                _nameController,
                'Student Name *',
                Icons.person,
                required: true,
              ),
              _field(
                _rollController,
                'Roll Number *',
                Icons.numbers,
                required: true,
              ),
              _field(
                _fatherController,
                "Father's Name *",
                Icons.person_outline,
                required: true,
              ),
              _field(
                _boardingController,
                'Boarding Point *',
                Icons.directions_bus,
                required: true,
              ),
              _field(
                _contactController,
                'Contact Number *',
                Icons.phone,
                required: true,
                keyboard: TextInputType.phone,
              ),
              _field(
                _phoneNumberController,
                'Phone Number *',
                Icons.phone_android,
                required: true,
                keyboard: TextInputType.phone,
              ),
              _field(
                _bloodGroupController,
                'Blood Group (Optional)',
                Icons.bloodtype,
              ),
              _field(_batchController, 'Batch (XI-XII)', Icons.school),
              _field(
                _admissionNumberController,
                'Admission Number',
                Icons.confirmation_number,
              ),
              _field(_dobController, 'Date of Birth', Icons.cake),
              _field(
                _addressController,
                'Address *',
                Icons.home,
                required: true,
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // ── Submit button ─────────────────────────────────
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0046A0),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.blue.shade200,
                ),
                child: _isSubmitting
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _submitStatus,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Text('Submit', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

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
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0046A0), width: 2),
          ),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                  ? 'This field is required'
                  : null
            : null,
      ),
    );
  }
}
