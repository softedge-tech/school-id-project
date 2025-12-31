// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// class AddStudentIdCardScreen extends StatefulWidget {
//   final String schoolId;
//   final String classId;

//   const AddStudentIdCardScreen({
//     super.key,
//     required this.schoolId,
//     required this.classId,
//   });

//   @override
//   State<AddStudentIdCardScreen> createState() => _AddStudentIdCardScreenState();
// }

// class _AddStudentIdCardScreenState extends State<AddStudentIdCardScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _picker = ImagePicker();

//   // Form controllers
//   final _studentNameController = TextEditingController();
//   final _admissionNumberController = TextEditingController();
//   final _standardController = TextEditingController();
//   final _dobController = TextEditingController();
//   final _bloodGroupController = TextEditingController();
//   final _parentNameController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _phoneController = TextEditingController();

//   // Image files
//   File? _frontImage;
//   File? _backImage;
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _studentNameController.dispose();
//     _admissionNumberController.dispose();
//     _standardController.dispose();
//     _dobController.dispose();
//     _bloodGroupController.dispose();
//     _parentNameController.dispose();
//     _addressController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage(bool isFront) async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1800,
//         maxHeight: 1800,
//         imageQuality: 85,
//       );

//       if (image != null) {
//         setState(() {
//           if (isFront) {
//             _frontImage = File(image.path);
//           } else {
//             _backImage = File(image.path);
//           }
//         });
//       }
//     } catch (e) {
//       _showErrorSnackBar('Error picking image: $e');
//     }
//   }

//   Future<void> _takePicture(bool isFront) async {
//     try {
//       final XFile? photo = await _picker.pickImage(
//         source: ImageSource.camera,
//         maxWidth: 1800,
//         maxHeight: 1800,
//         imageQuality: 85,
//       );

//       if (photo != null) {
//         setState(() {
//           if (isFront) {
//             _frontImage = File(photo.path);
//           } else {
//             _backImage = File(photo.path);
//           }
//         });
//       }
//     } catch (e) {
//       _showErrorSnackBar('Error taking picture: $e');
//     }
//   }

//   void _showImageSourceDialog(bool isFront) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text(
//           'Choose ${isFront ? 'Front' : 'Back'} Image Source',
//           style: const TextStyle(
//             color: Color(0xFF001F3F),
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF001F3F).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Icon(
//                   Icons.photo_library_rounded,
//                   color: Color(0xFF001F3F),
//                 ),
//               ),
//               title: const Text('Gallery'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage(isFront);
//               },
//             ),
//             const SizedBox(height: 8),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF001F3F).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Icon(
//                   Icons.camera_alt_rounded,
//                   color: Color(0xFF001F3F),
//                 ),
//               ),
//               title: const Text('Camera'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _takePicture(isFront);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _selectDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
//       firstDate: DateTime(1990),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF001F3F),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         _dobController.text =
//             '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
//       });
//     }
//   }

//   Future<void> _saveIdCard() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     if (_frontImage == null || _backImage == null) {
//       _showErrorSnackBar('Please upload both front and back images');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // TODO: Implement your Firebase/Backend upload logic here
//       // Upload images to storage
//       // Save student data to Firestore
      
//       await Future.delayed(const Duration(seconds: 2)); // Simulate upload

//       if (mounted) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Row(
//               children: [
//                 Icon(Icons.check_circle, color: Colors.white),
//                 SizedBox(width: 12),
//                 Text('ID Card added successfully'),
//               ],
//             ),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       _showErrorSnackBar('Error saving ID card: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error_outline, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   Widget _buildImageUploadCard({
//     required String title,
//     required bool isFront,
//     required File? imageFile,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF001F3F).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     isFront ? Icons.badge_outlined : Icons.info_outline,
//                     color: const Color(0xFF001F3F),
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF001F3F),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           GestureDetector(
//             onTap: () => _showImageSourceDialog(isFront),
//             child: Container(
//               margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//               height: 200,
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: imageFile != null
//                       ? const Color(0xFF001F3F)
//                       : Colors.grey[300]!,
//                   width: 2,
//                   style: imageFile != null ? BorderStyle.solid : BorderStyle.none,
//                 ),
//               ),
//               child: imageFile != null
//                   ? Stack(
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(10),
//                           child: Image.file(
//                             imageFile,
//                             width: double.infinity,
//                             height: double.infinity,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(8),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.2),
//                                   blurRadius: 4,
//                                 ),
//                               ],
//                             ),
//                             child: IconButton(
//                               icon: const Icon(
//                                 Icons.edit_rounded,
//                                 color: Color(0xFF001F3F),
//                               ),
//                               onPressed: () => _showImageSourceDialog(isFront),
//                             ),
//                           ),
//                         ),
//                       ],
//                     )
//                   : Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.add_photo_alternate_rounded,
//                           size: 48,
//                           color: Colors.grey[400],
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Tap to upload image',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 14,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Camera or Gallery',
//                           style: TextStyle(
//                             color: Colors.grey[400],
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     String? hint,
//     TextInputType? keyboardType,
//     int maxLines = 1,
//     bool readOnly = false,
//     VoidCallback? onTap,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hint,
//         prefixIcon: Icon(icon, color: const Color(0xFF001F3F)),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(
//             color: Color(0xFF001F3F),
//             width: 2,
//           ),
//         ),
//         filled: true,
//         fillColor: Colors.grey[50],
//       ),
//       keyboardType: keyboardType,
//       maxLines: maxLines,
//       readOnly: readOnly,
//       onTap: onTap,
//       validator: validator ?? (v) => v?.isEmpty ?? true ? 'Required' : null,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: const Color(0xFF001F3F),
//         foregroundColor: Colors.white,
//         title: const Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Add Student ID Card',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             Text(
//               'Upload front and back images',
//               style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
//             ),
//           ],
//         ),
//       ),
//       body: _isLoading
//           ? const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF001F3F)),
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'Uploading ID Card...',
//                     style: TextStyle(
//                       color: Color(0xFF001F3F),
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           : Form(
//               key: _formKey,
//               child: ListView(
//                 padding: const EdgeInsets.all(16),
//                 children: [
//                   // Student Information Section
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.05),
//                           blurRadius: 10,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF001F3F).withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: const Icon(
//                                 Icons.person_outline_rounded,
//                                 color: Color(0xFF001F3F),
//                                 size: 20,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             const Text(
//                               'Student Information',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Color(0xFF001F3F),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 20),
//                         _buildTextField(
//                           controller: _studentNameController,
//                           label: 'Student Name',
//                           icon: Icons.person,
//                           hint: 'Enter full name',
//                         ),
//                         const SizedBox(height: 16),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildTextField(
//                                 controller: _admissionNumberController,
//                                 label: 'Admission No.',
//                                 icon: Icons.numbers_rounded,
//                                 hint: 'e.g., 1653',
//                                 keyboardType: TextInputType.number,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: _buildTextField(
//                                 controller: _standardController,
//                                 label: 'Standard',
//                                 icon: Icons.class_outlined,
//                                 hint: 'e.g., I A',
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildTextField(
//                                 controller: _dobController,
//                                 label: 'Date of Birth',
//                                 icon: Icons.calendar_today_rounded,
//                                 hint: 'DD-MM-YYYY',
//                                 readOnly: true,
//                                 onTap: _selectDate,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: _buildTextField(
//                                 controller: _bloodGroupController,
//                                 label: 'Blood Group',
//                                 icon: Icons.water_drop_outlined,
//                                 hint: 'e.g., O+ve',
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         _buildTextField(
//                           controller: _parentNameController,
//                           label: 'Parent/Guardian Name',
//                           icon: Icons.family_restroom_rounded,
//                           hint: 'Enter parent name',
//                         ),
//                         const SizedBox(height: 16),
//                         _buildTextField(
//                           controller: _addressController,
//                           label: 'Address',
//                           icon: Icons.location_on_outlined,
//                           hint: 'Enter complete address',
//                           maxLines: 2,
//                         ),
//                         const SizedBox(height: 16),
//                         _buildTextField(
//                           controller: _phoneController,
//                           label: 'Phone Number',
//                           icon: Icons.phone_outlined,
//                           hint: 'Enter contact number',
//                           keyboardType: TextInputType.phone,
//                           validator: (v) {
//                             if (v?.isEmpty ?? true) return 'Required';
//                             if (v!.length != 10) return 'Enter valid 10-digit number';
//                             return null;
//                           },
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   // Front Image Upload
//                   _buildImageUploadCard(
//                     title: 'ID Card - Front Side',
//                     isFront: true,
//                     imageFile: _frontImage,
//                   ),

//                   const SizedBox(height: 16),

//                   // Back Image Upload
//                   _buildImageUploadCard(
//                     title: 'ID Card - Back Side',
//                     isFront: false,
//                     imageFile: _backImage,
//                   ),

//                   const SizedBox(height: 24),

//                   // Save Button
//                   ElevatedButton(
//                     onPressed: _saveIdCard,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF001F3F),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 2,
//                     ),
//                     child: const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.save_rounded),
//                         SizedBox(width: 8),
//                         Text(
//                           'Save ID Card',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 16),
//                 ],
//               ),
//             ),
//     );
//   }
// }