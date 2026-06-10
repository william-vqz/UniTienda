// lib/models/app_user.dart
enum UserRole { alumno, admin }

class AppUser {
  final String id;
  final String nombreCompleto;
  final String matricula;
  final String grado;
  final String grupo;
  final String email;
  final String telefono;
  final String password;
  final UserRole role;
  final DateTime createdAt;
  final String? profileImage;

  const AppUser({
    required this.id,
    required this.nombreCompleto,
    required this.matricula,
    required this.grado,
    required this.grupo,
    required this.email,
    required this.telefono,
    required this.password,
    required this.role,
    required this.createdAt,
    this.profileImage,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isAlumno => role == UserRole.alumno;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre_completo': nombreCompleto,
        'matricula': matricula,
        'grado': grado,
        'grupo': grupo,
        'email': email,
        'telefono': telefono,
        'password': password,
        'profile_image': profileImage ?? '',
        'role': role.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as String,
        nombreCompleto: map['nombre_completo'] as String,
        matricula: map['matricula'] as String,
        grado: map['grado'] as String,
        grupo: map['grupo'] as String,
        email: map['email'] as String,
        telefono: map['telefono'] as String,
        password: map['password'] as String,
        role: UserRole.values.firstWhere((e) => e.name == map['role']),
        createdAt: DateTime.parse(map['created_at'] as String),
        profileImage: map['profile_image'] as String?,
      );

  AppUser copyWith({
    String? password,
    String? profileImage,
  }) {
    return AppUser(
      id: id,
      nombreCompleto: nombreCompleto,
      matricula: matricula,
      grado: grado,
      grupo: grupo,
      email: email,
      telefono: telefono,
      password: password ?? this.password,
      role: role,
      createdAt: createdAt,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
