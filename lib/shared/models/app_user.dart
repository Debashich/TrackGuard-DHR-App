import 'app_language.dart';
import 'user_role.dart';

class AppUser {
  final String id;
  final String? fullName;
  final String email;
  final UserRole role;
  final String? assignedSection;
  final AppLanguage preferredLanguage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    this.fullName,
    required this.email,
    required this.role,
    this.assignedSection,
    this.preferredLanguage = AppLanguage.en,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    UserRole? role,
    String? assignedSection,
    AppLanguage? preferredLanguage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      assignedSection: assignedSection ?? this.assignedSection,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role.name,
      'assigned_section': assignedSection,
      'preferred_language': preferredLanguage.code,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      assignedSection: json['assigned_section'] as String?,
      preferredLanguage: AppLanguage.fromCode(
        json['preferred_language'] as String?,
      ),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
