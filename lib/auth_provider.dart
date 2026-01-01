import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'models.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> checkAuthState() async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentUser = await _firebaseService.getCurrentUserData();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      print("__________________________1111_____");

      _currentUser = await _firebaseService.signIn(email, password);
      if (_currentUser == null) {
        _error = 'Invalid credentials';
        return false;
      }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      _currentUser = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class SchoolProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<School> _schools = [];
  School? _selectedSchool;
  bool _isLoading = false;
  String? _error;

  List<School> get schools => _schools;
  School? get selectedSchool => _selectedSchool;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSchools() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _schools = await _firebaseService.getAllSchools();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSchool(String schoolId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _selectedSchool = await _firebaseService.getSchool(schoolId);
    } catch (e) {
      _error = e.toString();
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
   // UPLOAD IMAGE (Uint8List)
 
  Future<String> _uploadImageBytes({
    required Uint8List bytes,
    required String path,
  }) async {
    final ref = FirebaseStorage.instance.ref(path);

    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await task.ref.getDownloadURL();
  }

  Future<bool> createSchool({
  required String name,
  required String contactNumber,
  required String location,
  required String idCardPrefix,
  required String password,
  Uint8List? idCardFrontBytes,
  Uint8List? idCardBackBytes,
}) async {
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    String? frontImageUrl;
    String? backImageUrl;

    // Upload front image
    if (idCardFrontBytes != null) {
      print('Uploading front image...');
      frontImageUrl = await _uploadImageBytes(
        bytes: idCardFrontBytes,
        path: 'schools/$idCardPrefix/id_card_front.jpg',
      );
      print('Front image uploaded: $frontImageUrl');
    }

    // Upload back image
    if (idCardBackBytes != null) {
      print('Uploading back image...');
      backImageUrl = await _uploadImageBytes(
        bytes: idCardBackBytes,
        path: 'schools/$idCardPrefix/id_card_back.jpg',
      );
      print('Back image uploaded: $backImageUrl');
    }

    print('Creating school in Firestore...');
    final school = await _firebaseService.createSchool(
      name: name,
      contactNumber: contactNumber,
      location: location,
      idCardPrefix: idCardPrefix,
      password: password,
      frontIdCardUrl: frontImageUrl,  // ✅ Pass URLs to Firestore
      backIdCardUrl: backImageUrl,     // ✅ Pass URLs to Firestore
    );

    _schools.insert(0, school);
    print('School created successfully!');
    return true;
  } catch (e) {
    print('❌ ERROR creating school: $e');  // ✅ See the actual error
    _error = e.toString();
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<bool> updateSchool({
  required String id,
  required String name,
  required String contactNumber,
  required String location,
  required String idCardPrefix,
}) async {
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Firestore update
    await _firebaseService.updateSchool(id, {
      'name': name,
      'contactNumber': contactNumber,
      'location': location,
      'idCardPrefix': idCardPrefix,
    });

    // ✅ Update local list (NO reload)
    final index = _schools.indexWhere((s) => s.id == id);
    if (index != -1) {
      _schools[index] = _schools[index].copyWith(
        name: name,
        contactNumber: contactNumber,
        location: location,
        idCardPrefix: idCardPrefix,
      );
    }

    return true;
  } catch (e) {
    _error = e.toString();
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


  Future<bool> deleteSchool(String id) async {
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // 🔥 Delete from Firestore
    await _firebaseService.deleteSchool(id);

    // 🔥 Update local list (instant UI update)
    _schools.removeWhere((s) => s.id == id);

    return true;
  } catch (e) {
    _error = e.toString();
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class ClassProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<ClassModel> _classes = [];
  ClassModel? _selectedClass;
  bool _isLoading = false;
  String? _error;

  List<ClassModel> get classes => _classes;
  ClassModel? get selectedClass => _selectedClass;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadClasses(String schoolId) async {
    print('🔍 ClassProvider.loadClasses called for schoolId: $schoolId');
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('  ⏳ Loading classes from Firebase...');
      _classes = await _firebaseService.getClassesBySchool(schoolId);
      
      print('  ✅ Loaded ${_classes.length} classes:');
      for (var c in _classes) {
        print('    - ${c.className} (ID: ${c.id}, Active: ${c.isActive})');
      }
    } catch (e) {
      print('  ❌ Error loading classes: $e');
      _error = e.toString();
      _classes = []; // ✅ Clear on error
    } finally {
      _isLoading = false;
      print('  🏁 Loading complete. isLoading: $_isLoading');
      notifyListeners();
    }
  }

  Future<void> loadClass(String schoolId, String classId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _selectedClass = await _firebaseService.getClass(schoolId, classId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createClass({
    required String schoolId,
    required String className,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final classModel = await _firebaseService.createClass(
        schoolId: schoolId,
        className: className,
        password: password,
      );

      _classes.insert(0, classModel);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateClass({
    required String schoolId,
    required String classId,
    required String className,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.updateClass(
        schoolId,
        classId,
        {
          'className': className,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      final index = _classes.indexWhere((c) => c.id == classId);
      if (index != -1) {
        _classes[index] = _classes[index].copyWith(
          className: className,
        );
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteClass(String schoolId, String classId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.deleteClass(schoolId, classId);
      _classes.removeWhere((c) => c.id == classId);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String generateParentFormLink(String schoolId, String classId) {
    return _firebaseService.generateParentFormLink(schoolId, classId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
class StudentProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<Student> _students = [];
  Student? _selectedStudent;
  bool _isLoading = false;
  String? _error;

  List<Student> get students => _students;
  Student? get selectedStudent => _selectedStudent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStudents(String schoolId, String classId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _students = await _firebaseService.getStudentsByClass(schoolId, classId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudent(
    String schoolId,
    String classId,
    String studentId,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _selectedStudent = await _firebaseService.getStudent(
        schoolId,
        classId,
        studentId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addStudent(Student student, {required dynamic photo}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.addStudent(
        schoolId: student.schoolId,
        classId: student.classId,
        name: student.name,
        rollNumber: student.rollNumber,
        fatherName: student.fatherName,
        motherName: student.motherName,
        address: student.address,
        contactNumber: student.contactNumber,
        bloodGroup: student.bloodGroup,
        dateOfBirth: student.dateOfBirth,
        photo: photo,
      );

      await loadStudents(student.schoolId, student.classId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStudent({
    required String schoolId,
    required String classId,
    required String studentId,
    Map<String, dynamic>? data,
    dynamic newPhoto,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.updateStudent(
        schoolId: schoolId,
        classId: classId,
        studentId: studentId,
        name: data?['name'],
        rollNumber: data?['rollNumber'],
        fatherName: data?['fatherName'],
        motherName: data?['motherName'],
        address: data?['address'],
        contactNumber: data?['contactNumber'],
        bloodGroup: data?['bloodGroup'],
        dateOfBirth: data?['dateOfBirth'],
        newPhoto: newPhoto,
      );

      await loadStudents(schoolId, classId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteStudent(
    String schoolId,
    String classId,
    String studentId,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.softDeleteStudent(schoolId, classId, studentId);
      _students.removeWhere((s) => s.id == studentId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
