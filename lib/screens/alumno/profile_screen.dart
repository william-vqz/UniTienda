// lib/screens/alumno/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showChangePassword = false;
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isLoading = false;

  final _recoverEmailCtrl = TextEditingController();
  final _recoverMatriculaCtrl = TextEditingController();
  final _newRecoverPasswordCtrl = TextEditingController();
  final _confirmRecoverPasswordCtrl = TextEditingController();
  bool _showRecoverForm = false;
  bool _isRecovering = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _recoverEmailCtrl.dispose();
    _recoverMatriculaCtrl.dispose();
    _newRecoverPasswordCtrl.dispose();
    _confirmRecoverPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      await context.read<AuthProvider>().updateProfileImage(File(picked.path));
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Las contraseñas no coinciden'),
            backgroundColor: AppColors.alertError,
            duration: Duration(seconds: 5)),
      );
      return;
    }
    if (_newPasswordCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La contraseña debe tener al menos 4 caracteres'),
            backgroundColor: AppColors.alertError,
            duration: Duration(seconds: 5)),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await context.read<AuthProvider>().changePassword(
          currentPassword: _currentPasswordCtrl.text,
          newPassword: _newPasswordCtrl.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Contraseña cambiada exitosamente'),
            backgroundColor: AppColors.alertSuccess,
            duration: Duration(seconds: 5)),
      );
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      setState(() => _showChangePassword = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Las contraseñas no coinciden'),
            backgroundColor: AppColors.alertError,
            duration: Duration(seconds: 5)),
      );
    }
  }

  Future<void> _recoverPassword() async {
    if (_newRecoverPasswordCtrl.text != _confirmRecoverPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Las contraseñas no coinciden'),
            backgroundColor: AppColors.alertError,
            duration: Duration(seconds: 5)),
      );
      return;
    }
    if (_newRecoverPasswordCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La contraseña debe tener al menos 4 caracteres'),
            backgroundColor: AppColors.alertError,
            duration: Duration(seconds: 5)),
      );
      return;
    }

    setState(() => _isRecovering = true);
    final success = await context.read<AuthProvider>().recoverPassword(
          email: _recoverEmailCtrl.text.trim(),
          matricula: _recoverMatriculaCtrl.text.trim(),
          newPassword: _newRecoverPasswordCtrl.text,
        );
    if (!mounted) return;
    setState(() => _isRecovering = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Contraseña restablecida exitosamente'),
            backgroundColor: AppColors.alertSuccess,
            duration: Duration(seconds: 5)),
      );
      _recoverEmailCtrl.clear();
      _recoverMatriculaCtrl.clear();
      _newRecoverPasswordCtrl.clear();
      _confirmRecoverPasswordCtrl.clear();
      setState(() => _showRecoverForm = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La contraseña debe tener al menos 4 caracteres'),
            backgroundColor: AppColors.alertError,
            duration: Duration(seconds: 5)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant,
                  border: Border.all(color: AppColors.primary, width: 3),
                  image:
                      user.profileImage != null && user.profileImage!.isNotEmpty
                          ? DecorationImage(
                              image: FileImage(File(user.profileImage!)),
                              fit: BoxFit.cover)
                          : null,
                ),
                child: user.profileImage == null || user.profileImage!.isEmpty
                    ? const Icon(Icons.person, size: 60, color: AppColors.primary)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt, size: 16),
              label: const Text('Cambiar foto de perfil'),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(user),
            const SizedBox(height: 20),
            if (!_showRecoverForm)
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _showChangePassword = !_showChangePassword;
                  _showRecoverForm = false;
                }),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Cambiar contraseña'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.secondary,
                ),
              ),
            if (_showChangePassword) _buildChangePasswordForm(),
            const SizedBox(height: 16),
            if (!_showChangePassword)
              TextButton.icon(
                onPressed: () => setState(() {
                  _showRecoverForm = !_showRecoverForm;
                  _showChangePassword = false;
                }),
                icon: const Icon(Icons.help_outline),
                label: const Text('¿Olvidaste tu contraseña?'),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.alertInfo),
              ),
            if (_showRecoverForm) _buildRecoverPasswordForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(AppUser user) {
    final isAdmin = user.role == UserRole.admin;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _infoRow(
              Icons.person_outline, 'Nombre completo', user.nombreCompleto),
          if (isAdmin) ...[
            const Divider(),
            _infoRow(Icons.admin_panel_settings, 'Rol', 'Administrador'),
          ] else ...[
            const Divider(),
            _infoRow(Icons.badge_outlined, 'Matrícula', user.matricula),
            const Divider(),
            _infoRow(Icons.school_outlined, 'Grado', '${user.grado}°'),
            const Divider(),
            _infoRow(Icons.group_outlined, 'Grupo', user.grupo),
          ],
          const Divider(),
          _infoRow(Icons.email_outlined, 'Correo', user.email),
          if (!isAdmin) ...[
            const Divider(),
            _infoRow(Icons.phone_outlined, 'Teléfono', user.telefono),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text(value,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          TextField(
            controller: _currentPasswordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña actual',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar nueva contraseña',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showChangePassword = false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecoverPasswordForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text('Restablecer contraseña',
              style: GoogleFonts.nunito(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Ingresa tu correo y matrícula para restablecer tu contraseña',
              style: GoogleFonts.nunito(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: _recoverEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _recoverMatriculaCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Matrícula',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          TextField(
            controller: _newRecoverPasswordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmRecoverPasswordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar nueva contraseña',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showRecoverForm = false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isRecovering ? null : _recoverPassword,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alertInfo),
                  child: _isRecovering
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Restablecer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
