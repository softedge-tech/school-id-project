import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

// ─────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────
class _AppColors {
  static const primary = Color(0xFF0A3D91);
  static const primaryLight = Color(0xFF1A5AC8);
  static const accent = Color(0xFF00C6FF);
  static const surface = Color(0xFFF4F7FE);
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0D1B3E);
  static const textSecondary = Color(0xFF6B7A99);
  static const border = Color(0xFFE2E8F5);
  static const success = Color(0xFF00C896);
  static const error = Color(0xFFFF4D6A);
}

// ─────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────
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

class _ParentFormScreenState extends State<ParentFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _fatherController = TextEditingController();
  final _boardingController = TextEditingController();
  final _addressController1 = TextEditingController();
  final _addressController2 = TextEditingController();
  final _addressController3 = TextEditingController();
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
  int _submitProgress = 0; // 0–4

  late AnimationController _fadeCtrl;
  late AnimationController _successCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  static const String _removeBgApiKey = 'JN8MSbSLnCZVgaLe4HnX9Noh';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scaleAnim = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _successCtrl.dispose();
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _allControllers => [
    _nameController,
    _rollController,
    _fatherController,
    _boardingController,
    _addressController1,
    _addressController2,
    _addressController3,
    _contactController,
    _phoneNumberController,
    _bloodGroupController,
    _batchController,
    _dobController,
    _admissionNumberController,
  ];

  // ── Image helpers ────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _photoBytes = bytes);
    }
  }

  static Uint8List _resizeImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    if (image.width <= 800 && image.height <= 800) return bytes;
    final resized = image.width > image.height
        ? img.copyResize(image, width: 800)
        : img.copyResize(image, height: 800);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
  }

  Future<Uint8List> _removeBackground(Uint8List imageBytes) async {
    final resized = await compute(_resizeImage, imageBytes);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.remove.bg/v1.0/removebg'),
    );
    request.headers['X-Api-Key'] = _removeBgApiKey;
    request.fields['size'] = 'auto';
    request.fields['format'] = 'png';
    request.files.add(
      http.MultipartFile.fromBytes(
        'image_file',
        resized,
        filename: 'photo.jpg',
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) return response.bodyBytes;
    final body = jsonDecode(response.body);
    final msg = (body['errors'] as List?)?.first?['title'] ?? 'Unknown error';
    throw Exception('remove.bg: $msg');
  }

  // ── Submit ───────────────────────────────────────────────────
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photoBytes == null) {
      _showSnack('Please upload a student photo', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitProgress = 1;
      _submitStatus = 'Removing background…';
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

      // Step 1 – Remove background
      Uint8List transparentBytes;
      try {
        transparentBytes = await _removeBackground(_photoBytes!);
      } catch (e) {
        _showSnack('Background removal failed: $e', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      // Step 2 – skipped (no colour background added)

      // Step 3 – Upload transparent PNG
      setState(() {
        _submitProgress = 3;
        _submitStatus = 'Uploading photo…';
      });
      final storageRef = storage.ref().child(
        'students/${widget.schoolId}/${widget.classId}/$studentId'
        '/${DateTime.now().millisecondsSinceEpoch}.png',
      );
      final uploadTask = await storageRef.putData(
        transparentBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      final photoUrl = await uploadTask.ref.getDownloadURL();

      // Step 4 – Save to Firestore
      setState(() {
        _submitProgress = 4;
        _submitStatus = 'Saving student data…';
      });
      await studentRef.set({
        'schoolId': widget.schoolId,
        'classId': widget.classId,
        'name': _nameController.text.trim(),
        'rollNumber': _rollController.text.trim(),
        'fatherName': _fatherController.text.trim(),
        'motherName': _boardingController.text.trim(),
        'address1': _addressController1.text.trim(),
        'address2': _addressController2.text.trim(),
        'address3': _addressController3.text.trim(),
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
      _successCtrl.forward();
    } catch (e) {
      _showSnack('Submission failed: $e', isError: true);
    } finally {
      if (mounted)
        setState(() {
          _isSubmitting = false;
          _submitStatus = '';
          _submitProgress = 0;
        });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: isError ? _AppColors.error : _AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _isSubmitted = false;
      _photoBytes = null;
    });
    _successCtrl.reset();
    _fadeCtrl.forward(from: 0);
    _formKey.currentState?.reset();
    for (final c in _allControllers) c.clear();
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: _AppColors.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _buildPhotoPicker(),
                      const SizedBox(height: 28),
                      _buildSectionLabel('Student Information'),
                      const SizedBox(height: 12),
                      _buildCard([
                        _field(
                          _nameController,
                          'Student Name',
                          Icons.person_rounded,
                          required: true,
                        ),
                        _field(
                          _rollController,
                          'Roll Number',
                          Icons.tag_rounded,
                          required: true,
                        ),
                        _field(
                          _admissionNumberController,
                          'Admission Number',
                          Icons.confirmation_number_rounded,
                        ),
                        _field(
                          _batchController,
                          'Batch (e.g. XI–XII)',
                          Icons.school_rounded,
                        ),
                        _field(
                          _dobController,
                          'Date of Birth',
                          Icons.cake_rounded,
                        ),
                        _field(
                          _bloodGroupController,
                          'Blood Group',
                          Icons.bloodtype_rounded,
                          isLast: true,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Guardian Details'),
                      const SizedBox(height: 12),
                      _buildCard([
                        _field(
                          _fatherController,
                          "Father's Name",
                          Icons.person_outline_rounded,
                          required: true,
                        ),
                        _field(
                          _boardingController,
                          'Boarding Point',
                          Icons.directions_bus_rounded,
                          required: true,
                        ),
                        _field(
                          _contactController,
                          'Contact Number',
                          Icons.phone_rounded,
                          required: true,
                          keyboard: TextInputType.phone,
                        ),
                        _field(
                          _phoneNumberController,
                          'Alternate Phone',
                          Icons.phone_android_rounded,
                          keyboard: TextInputType.phone,
                          isLast: true,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Address'),
                      const SizedBox(height: 12),
                      _buildCard([
                        _field(
                          _addressController1,
                          'Address Line 1',
                          Icons.home_rounded,
                          required: true,
                          maxLines: 2,
                        ),
                        _field(
                          _addressController2,
                          'Address Line 2',
                          Icons.location_on_rounded,
                          required: true,
                          maxLines: 2,
                        ),
                        _field(
                          _addressController3,
                          'Address Line 3',
                          Icons.map_rounded,
                          required: true,
                          maxLines: 2,
                          isLast: true,
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver App Bar ───────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: _AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Student ID Card',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Fill in your child\'s details',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A3D91), Color(0xFF1A5AC8)],
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Photo Picker ─────────────────────────────────────────────
  Widget _buildPhotoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _isSubmitting ? null : _pickImage,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 130,
          height: 155,
          decoration: BoxDecoration(
            color: _photoBytes != null ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _photoBytes != null
                  ? _AppColors.primaryLight
                  : _AppColors.border,
              width: _photoBytes != null ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _AppColors.primary.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _photoBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_photoBytes!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        color: _AppColors.primary.withOpacity(0.7),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Change',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo_rounded,
                        size: 24,
                        color: _AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Upload Photo',
                      style: TextStyle(
                        color: _AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap to select',
                      style: TextStyle(
                        color: _AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Section Label ────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _AppColors.primaryLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ── Card Wrapper ─────────────────────────────────────────────
  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ── Form Field ───────────────────────────────────────────────
  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 15,
              color: _AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: required ? '$label *' : label,
              labelStyle: const TextStyle(
                color: _AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 4, right: 2),
                child: Icon(icon, size: 20, color: _AppColors.textSecondary),
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null,
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: _AppColors.border,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }

  // ── Submit Button ────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return Column(
      children: [
        if (_isSubmitting) ...[
          _buildProgressIndicator(),
          const SizedBox(height: 16),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _isSubmitting
                ? const LinearGradient(
                    colors: [Color(0xFF6A90C8), Color(0xFF5A80B8)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A5AC8), Color(0xFF0A3D91)],
                  ),
            boxShadow: _isSubmitting
                ? []
                : [
                    BoxShadow(
                      color: _AppColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isSubmitting ? null : _submitForm,
              child: Center(
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing…',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Submit Form',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Progress Stepper ─────────────────────────────────────────
  Widget _buildProgressIndicator() {
    final steps = ['Background', 'Upload', 'Saving'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIndex = (i ~/ 2) + 1;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 2,
                    color: stepIndex < _submitProgress
                        ? _AppColors.success
                        : _AppColors.border,
                  ),
                );
              }
              final stepIndex = (i ~/ 2) + 1;
              final isDone = stepIndex < _submitProgress;
              final isActive = stepIndex == _submitProgress;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? _AppColors.success
                      : isActive
                      ? _AppColors.primaryLight
                      : _AppColors.border,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        )
                      : isActive
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '$stepIndex',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : _AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            _submitStatus,
            style: const TextStyle(
              fontSize: 12,
              color: _AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Success Screen ───────────────────────────────────────────
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: _AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF00E4A8), Color(0xFF00C896)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C896).withOpacity(0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Submitted!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Student details have been saved\nand the ID card is being generated.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Add Another Student',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    color: _AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
