import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'models.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ========== AUTHENTICATION ==========

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data()!, userDoc.id);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print(e);
      throw 'Login failed: ${e.toString()}';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<UserModel?> getCurrentUserData() async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch user data: ${e.toString()}';
    }
  }

  // ========== SCHOOL OPERATIONS ==========

  Future<School> createSchool({
    required String name,
    required String contactNumber,
    required String location,
    required String idCardPrefix,
    required String password,
  }) async {
    try {
      final schoolId = _firestore.collection('schools').doc().id;
      final schoolLoginId = 'SCHOOL${DateTime.now().millisecondsSinceEpoch}';

      // Create school admin user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: '$schoolLoginId@school.portal',
        password: password,
      );

      final school = School(
        id: schoolId,
        name: name,
        contactNumber: contactNumber,
        location: location,
        schoolLoginId: schoolLoginId,
        idCardPrefix: idCardPrefix,
        createdAt: DateTime.now(),
      );

      // Save school data
      await _firestore.collection('schools').doc(schoolId).set(school.toMap());

      // Save user data
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': '$schoolLoginId@school.portal',
        'role': 'school_admin',
        'schoolId': schoolId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return school;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to create school: ${e.toString()}';
    }
  }

 Future<void> updateSchool(String schoolId, Map<String, dynamic> data) async {
  try {
    await _firestore.collection('schools').doc(schoolId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    throw Exception('Failed to update school: $e');
  }
}


  Future<void> deleteSchool(String schoolId) async {
  try {
    await _firestore.collection('schools').doc(schoolId).delete();
  } catch (e) {
    throw Exception('Failed to delete school: $e');
  }
}


 Future<List<School>> getAllSchools() async {
  try {
    final snapshot = await _firestore
        .collection('schools')
        .orderBy('createdAt', descending: true)
        .get();

    // Filter active schools in code instead of Firestore
    return snapshot.docs
        .map((doc) => School.fromMap(doc.data(), doc.id))
        .where((school) => school.isActive ?? true) // Filter in memory
        .toList();
  } catch (e) {
    throw 'Failed to fetch schools: ${e.toString()}';
  }
}

  Future<School?> getSchool(String schoolId) async {
    try {
      final doc = await _firestore.collection('schools').doc(schoolId).get();
      if (doc.exists) {
        return School.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch school: ${e.toString()}';
    }
  }

  // ========== CLASS OPERATIONS ==========

  Future<ClassModel> createClass({
  required String schoolId,
  required String className,
  required String password,
}) async {
  try {
    final classId = _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc()
        .id;

    final teacherLoginId = 'CLASS${DateTime.now().millisecondsSinceEpoch}';

    // Create teacher user
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: '$teacherLoginId@teacher.portal',
      password: password,
    );

    final classModel = ClassModel(
      id: classId,
      schoolId: schoolId,
      className: className,
      teacherLoginId: teacherLoginId,
      teacherUid: userCredential.user!.uid,
      createdAt: DateTime.now(),
      isActive: true, // ✅ Explicitly set this
    );

    // Save class data with isActive field
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .set(classModel.toMap()); // toMap() should include isActive

    // Save teacher user data
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'email': '$teacherLoginId@teacher.portal',
      'role': 'teacher',
      'schoolId': schoolId,
      'classId': classId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return classModel;
  } on FirebaseAuthException catch (e) {
    throw _handleAuthException(e);
  } catch (e) {
    throw 'Failed to create class: ${e.toString()}';
  }
}

  Future<void> updateClass(
    String schoolId,
    String classId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .update(data);
    } catch (e) {
      throw 'Failed to update class: ${e.toString()}';
    }
  }

  Future<void> deleteClass(String schoolId, String classId) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .update({
            'isActive': false,
            'deletedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw 'Failed to delete class: ${e.toString()}';
    }
  }

 Future<List<ClassModel>> getClassesBySchool(String schoolId) async {
  try {
    print('📡 Firebase: getClassesBySchool($schoolId)');
    
    final snapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        // ✅ REMOVE THIS LINE IF IT EXISTS:
        // .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    print('  📦 Got ${snapshot.docs.length} documents from Firestore');
    
    final classes = snapshot.docs
        .map((doc) {
          print('    - Doc ID: ${doc.id}, Data: ${doc.data()}');
          return ClassModel.fromMap(doc.data(), doc.id);
        })
        .toList();
    
    return classes;
  } catch (e) {
    print('  ❌ Error in getClassesBySchool: $e');
    rethrow;
  }
}

  Future<ClassModel?> getClass(String schoolId, String classId) async {
    try {
      final doc = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .get();

      if (doc.exists) {
        return ClassModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch class: ${e.toString()}';
    }
  }

  // ========== STUDENT OPERATIONS ==========

  Future<Student> addStudent({
    required String schoolId,
    required String classId,
    required String name,
    required String rollNumber,
    required String fatherName,
    required String motherName,
    required String address,
    required String contactNumber,
    String? bloodGroup,
    DateTime? dateOfBirth,
    File? photo,
  }) async {
    try {
      final studentId = _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc()
          .id;

      String? photoUrl;
      if (photo != null) {
        photoUrl = await _uploadStudentPhoto(
          schoolId: schoolId,
          classId: classId,
          studentId: studentId,
          photo: photo,
        );
      }

      final student = Student(
        id: studentId,
        schoolId: schoolId,
        classId: classId,
        name: name,
        rollNumber: rollNumber,
        fatherName: fatherName,
        motherName: motherName,
        address: address,
        contactNumber: contactNumber,
        photoUrl: photoUrl,
        bloodGroup: bloodGroup,
        dateOfBirth: dateOfBirth,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .set(student.toMap());

      return student;
    } catch (e) {
      throw 'Failed to add student: ${e.toString()}';
    }
  }

  Future<void> updateStudent({
    required String schoolId,
    required String classId,
    required String studentId,
    String? name,
    String? rollNumber,
    String? fatherName,
    String? motherName,
    String? address,
    String? contactNumber,
    String? bloodGroup,
    DateTime? dateOfBirth,
    File? newPhoto,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (rollNumber != null) updates['rollNumber'] = rollNumber;
      if (fatherName != null) updates['fatherName'] = fatherName;
      if (motherName != null) updates['motherName'] = motherName;
      if (address != null) updates['address'] = address;
      if (contactNumber != null) updates['contactNumber'] = contactNumber;
      if (bloodGroup != null) updates['bloodGroup'] = bloodGroup;
      if (dateOfBirth != null) {
        updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      }

      if (newPhoto != null) {
        final photoUrl = await _uploadStudentPhoto(
          schoolId: schoolId,
          classId: classId,
          studentId: studentId,
          photo: newPhoto,
        );
        updates['photoUrl'] = photoUrl;
      }

      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .update(updates);
    } catch (e) {
      throw 'Failed to update student: ${e.toString()}';
    }
  }

  Future<void> softDeleteStudent(
    String schoolId,
    String classId,
    String studentId,
  ) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .update({
            'isDeleted': true,
            'deletedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw 'Failed to delete student: ${e.toString()}';
    }
  }

  Future<List<Student>> getStudentsByClass(
    String schoolId,
    String classId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .collection('students')
          .where('isDeleted', isEqualTo: false)
          .orderBy('rollNumber')
          .get();

      return snapshot.docs
          .map((doc) => Student.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw 'Failed to fetch students: ${e.toString()}';
    }
  }

  Future<Student?> getStudent(
    String schoolId,
    String classId,
    String studentId,
  ) async {
    try {
      final doc = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .get();

      if (doc.exists) {
        return Student.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch student: ${e.toString()}';
    }
  }

  // ========== STORAGE OPERATIONS ==========

  Future<String> _uploadStudentPhoto({
    required String schoolId,
    required String classId,
    required String studentId,
    required File photo,
  }) async {
    try {
      final ref = _storage.ref().child(
        'students/$schoolId/$classId/$studentId/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final uploadTask = await ref.putFile(photo);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload photo: ${e.toString()}';
    }
  }

  // ========== HELPER METHODS ==========

  String generateParentFormLink(String schoolId, String classId) {
    return 'http://localhost:64373/#/parent-form/$schoolId/$classId';
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
