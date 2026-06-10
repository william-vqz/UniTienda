// lib/core/database/user_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../models/app_user.dart';
import 'db_helper.dart';

class UserDao {
  UserDao._();
  static final UserDao instance = UserDao._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<void> insertUser(AppUser user) async {
    final db = await _db;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await _db;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  Future<AppUser?> getUserByMatricula(String matricula) async {
    final db = await _db;
    final result = await db.query(
      'users',
      where: 'matricula = ?',
      whereArgs: [matricula.toUpperCase()],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  Future<AppUser?> getUserById(String id) async {
    final db = await _db;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  Future<bool> emailExists(String email) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM users WHERE email = ?',
        [email.trim().toLowerCase()],
      ),
    );
    return (count ?? 0) > 0;
  }

  Future<bool> matriculaExists(String matricula) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM users WHERE matricula = ?',
        [matricula.toUpperCase()],
      ),
    );
    return (count ?? 0) > 0;
  }

  Future<List<AppUser>> getAllAlumnos() async {
    final db = await _db;
    final result = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['alumno'],
      orderBy: 'nombre_completo ASC',
    );
    return result.map((r) => AppUser.fromMap(r)).toList();
  }

  Future<AppUser?> getAdminUser() async {
    final db = await _db;
    final result = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['admin'],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  Future<void> updateProfileImage(String userId, String imagePath) async {
    final db = await _db;
    await db.update(
      'users',
      {'profile_image': imagePath},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updatePassword(String userId, String newPassword) async {
    final db = await _db;
    await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
