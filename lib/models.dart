import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  superAdmin,
  schoolAdmin,
  teacher,
}

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String? schoolId;
  final String? classId;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.schoolId,
    this.classId,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      role: _parseRole(map['role']),
      schoolId: map['schoolId'],
      classId: map['classId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role.name,
      'schoolId': schoolId,
      'classId': classId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'school_admin':
        return UserRole.schoolAdmin;
      case 'teacher':
        return UserRole.teacher;
      default:
        return UserRole.teacher;
    }
  }
}

class School {
  final String id;
  final String name;
  final String contactNumber;
  final String location;
  final String schoolLoginId;
  final String idCardPrefix;
  final DateTime createdAt;
  final bool isActive;

  School({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.location,
    required this.schoolLoginId,
    required this.idCardPrefix,
    required this.createdAt,
    this.isActive = true,
  });

  factory School.fromMap(Map<String, dynamic> map, String id) {
    return School(
      id: id,
      name: map['name'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      location: map['location'] ?? '',
      schoolLoginId: map['schoolLoginId'] ?? '',
      idCardPrefix: map['idCardPrefix'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contactNumber': contactNumber,
      'location': location,
      'schoolLoginId': schoolLoginId,
      'idCardPrefix': idCardPrefix,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
  School copyWith({
  String? name,
  String? contactNumber,
  String? location,
  String? schoolLoginId,
  String? idCardPrefix,
  bool? isActive,
}) {
  return School(
    id: id,
    name: name ?? this.name,
    contactNumber: contactNumber ?? this.contactNumber,
    location: location ?? this.location,
    schoolLoginId: schoolLoginId ?? this.schoolLoginId,
    idCardPrefix: idCardPrefix ?? this.idCardPrefix,
    createdAt: createdAt, // keep original
    isActive: isActive ?? this.isActive,
  );
}

}


class ClassModel {
  final String id;
  final String schoolId;
  final String className;
  final String teacherLoginId;
  final String? teacherUid;
  final DateTime createdAt;
  final bool isActive;

  ClassModel({
    required this.id,
    required this.schoolId,
    required this.className,
    required this.teacherLoginId,
    this.teacherUid,
    required this.createdAt,
    this.isActive = true,
  });

  factory ClassModel.fromMap(Map<String, dynamic> map, String id) {
    return ClassModel(
      id: id,
      schoolId: map['schoolId'] ?? '',
      className: map['className'] ?? '',
      teacherLoginId: map['teacherLoginId'] ?? '',
      teacherUid: map['teacherUid'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'className': className,
      'teacherLoginId': teacherLoginId,
      'teacherUid': teacherUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
  ClassModel copyWith({
  String? className,
  String? teacherLoginId,
  String? teacherUid,
  DateTime? createdAt,
  bool? isActive,
}) {
  return ClassModel(
    id: id,
    schoolId: schoolId,
    className: className ?? this.className,
    teacherLoginId: teacherLoginId ?? this.teacherLoginId,
    teacherUid: teacherUid ?? this.teacherUid,
    createdAt: createdAt ?? this.createdAt,
    isActive: isActive ?? this.isActive,
  );
}

}

class Student {
  final String id;
  final String schoolId;
  final String classId;
  final String name;
  final String rollNumber;
  final String fatherName;
  final String motherName;
  final String address;
  final String contactNumber;
  final String? photoUrl;
  final String? bloodGroup;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  Student({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.name,
    required this.rollNumber,
    required this.fatherName,
    required this.motherName,
    required this.address,
    required this.contactNumber,
    this.photoUrl,
    this.bloodGroup,
    this.dateOfBirth,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory Student.fromMap(Map<String, dynamic> map, String id) {
    return Student(
      id: id,
      schoolId: map['schoolId'] ?? '',
      classId: map['classId'] ?? '',
      name: map['name'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      fatherName: map['fatherName'] ?? '',
      motherName: map['motherName'] ?? '',
      address: map['address'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      photoUrl: map['photoUrl'],
      bloodGroup: map['bloodGroup'],
      dateOfBirth: map['dateOfBirth'] != null
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'classId': classId,
      'name': name,
      'rollNumber': rollNumber,
      'fatherName': fatherName,
      'motherName': motherName,
      'address': address,
      'contactNumber': contactNumber,
      'photoUrl': photoUrl,
      'bloodGroup': bloodGroup,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : null,
      'isDeleted': isDeleted,
    };
  }

  Student copyWith({
    String? name,
    String? rollNumber,
    String? fatherName,
    String? motherName,
    String? address,
    String? contactNumber,
    String? photoUrl,
    String? bloodGroup,
    DateTime? dateOfBirth,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Student(
      id: id,
      schoolId: schoolId,
      classId: classId,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}