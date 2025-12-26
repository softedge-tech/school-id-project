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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSchool({
    required String name,
    required String contactNumber,
    required String location,
    required String idCardPrefix,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final school = await _firebaseService.createSchool(
        name: name,
        contactNumber: contactNumber,
        location: location,
        idCardPrefix: idCardPrefix,
        password: password,
      );

      _schools.insert(0, school);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSchool(String schoolId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.updateSchool(schoolId, data);
      await loadSchools();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSchool(String schoolId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.deleteSchool(schoolId);
      _schools.removeWhere((s) => s.id == schoolId);
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
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _classes = await _firebaseService.getClassesBySchool(schoolId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
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

  Future<bool> updateClass(
    String schoolId,
    String classId,
    Map<String, dynamic> data,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.updateClass(schoolId, classId, data);
      await loadClasses(schoolId);
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