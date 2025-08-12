import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String fullname;
  final String email;
  final String role;
  final String? profilePicture;

  UserModel({
    required this.id,
    required this.fullname,
    required this.email,
    this.role = 'user',
    this.profilePicture,
  });

  // Convert model to JSON for storing in Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'email': email,
      'role': role,
      'profilePicture': profilePicture,
    };
  }

  // Create model from Firestore JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      profilePicture: json['profilePicture'],
    );
  }

  // Create model from Firestore DocumentSnapshot
  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    data['id'] = snapshot.id;
    return UserModel.fromJson(data);
  }

  // Create a copy of the user with some fields changed
  UserModel copyWith({
    String? id,
    String? fullname,
    String? email,
    String? role,
    String? profilePicture,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullname: fullname ?? this.fullname,
      email: email ?? this.email,
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}
