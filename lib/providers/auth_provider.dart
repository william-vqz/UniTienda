// lib/providers/auth_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/database/user_dao.dart';
import '../models/app_user.dart';

class AuthProvider with ChangeNotifier {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isAlumno => _currentUser?.role == UserRole.alumno;
  String get displayName => _currentUser?.nombreCompleto ?? '';
  String get studentId => _currentUser?.id ?? '';
  String get studentMatricula => _currentUser?.matricula ?? '';
  String get studentGrado => _currentUser?.grado ?? '';
  String get studentGrupo => _currentUser?.grupo ?? '';
  String get studentEmail => _currentUser?.email ?? '';
  String get studentTelefono => _currentUser?.telefono ?? '';

  static const _kId = 'auth_id';
  static const _kNombre = 'auth_nombre';
  static const _kMatricula = 'auth_matricula';
  static const _kEmail = 'auth_email';
  static const _kRole = 'auth_role';
  static const _kAdminPassword = 'auth_admin_password';

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kId);
    if (id == null) return;

    if (id == 'admin-001') {
      final adminPwd = prefs.getString(_kAdminPassword) ?? 'admin1234';
      final adminImage = prefs.getString('auth_image');
      _currentUser = AppUser(
        id: 'admin-001',
        nombreCompleto: prefs.getString(_kNombre) ?? 'Administrador',
        matricula: 'ADMIN',
        grado: '-',
        grupo: '-',
        email: prefs.getString(_kEmail) ?? 'admin@gmail.com',
        telefono: '-',
        password: adminPwd,
        role: UserRole.admin,
        profileImage: adminImage,
        createdAt: DateTime.now(),
      );
      notifyListeners();
      return;
    }

    final user = await UserDao.instance.getUserById(id);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String nombreCompleto,
    required String matricula,
    required String grado,
    required String grupo,
    required String email,
    required String telefono,
    required String password,
  }) async {
    final emailExists = await UserDao.instance.emailExists(email);
    if (emailExists) return false;

    final matriculaExists = await UserDao.instance.matriculaExists(matricula);
    if (matriculaExists) return false;

    final user = AppUser(
      id: const Uuid().v4(),
      nombreCompleto: nombreCompleto.trim(),
      matricula: matricula.trim().toUpperCase(),
      grado: grado.trim(),
      grupo: grupo.trim().toUpperCase(),
      email: email.trim().toLowerCase(),
      telefono: telefono.trim(),
      password: password,
      role: UserRole.alumno,
      createdAt: DateTime.now(),
    );

    await UserDao.instance.insertUser(user);

    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kId, user.id);
    await prefs.setString(_kNombre, user.nombreCompleto);
    await prefs.setString(_kMatricula, user.matricula);
    await prefs.setString(_kEmail, user.email);
    await prefs.setString(_kRole, user.role.name);

    notifyListeners();
    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().toLowerCase() == 'admin@gmail.com' &&
        password == 'admin1234') {
      final adminUser = AppUser(
        id: 'admin-001',
        nombreCompleto: 'Administrador',
        matricula: 'ADMIN',
        grado: '-',
        grupo: '-',
        email: 'admin@gmail.com',
        telefono: '-',
        password: 'admin1234',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );
      _currentUser = adminUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kId, adminUser.id);
      await prefs.setString(_kNombre, adminUser.nombreCompleto);
      await prefs.setString(_kMatricula, adminUser.matricula);
      await prefs.setString(_kEmail, adminUser.email);
      await prefs.setString(_kRole, adminUser.role.name);
      await prefs.setString(_kAdminPassword, adminUser.password);

      notifyListeners();
      return true;
    }

    final user = await UserDao.instance.getUserByEmail(email);
    if (user == null || user.password != password) return false;

    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kId, user.id);
    await prefs.setString(_kNombre, user.nombreCompleto);
    await prefs.setString(_kMatricula, user.matricula);
    await prefs.setString(_kEmail, user.email);
    await prefs.setString(_kRole, user.role.name);

    notifyListeners();
    return true;
  }

  Future<void> updateProfileImage(File image) async {
    if (_currentUser == null) return;

    final imagePath = image.path;
    if (_currentUser!.id == 'admin-001') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_image', imagePath);
      _currentUser = _currentUser!.copyWith(profileImage: imagePath);
      notifyListeners();
      return;
    }

    await UserDao.instance.updateProfileImage(_currentUser!.id, imagePath);

    _currentUser = _currentUser!.copyWith(profileImage: imagePath);

    notifyListeners();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;
    if (_currentUser!.password != currentPassword) return false;

    if (_currentUser!.id == 'admin-001') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAdminPassword, newPassword);
      _currentUser = _currentUser!.copyWith(password: newPassword);
      notifyListeners();
      return true;
    }

    await UserDao.instance.updatePassword(_currentUser!.id, newPassword);
    _currentUser = _currentUser!.copyWith(password: newPassword);

    notifyListeners();
    return true;
  }

  Future<bool> recoverPassword({
    required String email,
    required String matricula,
    required String newPassword,
  }) async {
    final user = await UserDao.instance.getUserByEmail(email);
    if (user == null || user.matricula != matricula.toUpperCase()) return false;

    await UserDao.instance.updatePassword(user.id, newPassword);
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
