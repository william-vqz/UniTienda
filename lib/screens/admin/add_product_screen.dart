// lib/screens/admin/add_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _newCategoryCtrl = TextEditingController();

  String? _selectedCategory;
  bool _useNewCategory = false;
  String? _imagePath;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final category = _useNewCategory
          ? _newCategoryCtrl.text.trim()
          : _selectedCategory ?? '';
      if (category.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selecciona o escribe una categoría'),
              backgroundColor: AppColors.alertError,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final id = const Uuid().v4();
      final product = Product(
        id: id,
        name: _nameCtrl.text.trim(),
        category: category,
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        imageUrl: _imagePath ?? '',
        description: _descCtrl.text.trim(),
        stockBySize: {for (final s in Product.standardSizes) s: 0},
      );

      await context.read<ProductProvider>().addProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto agregado correctamente'),
            backgroundColor: AppColors.alertSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al agregar producto'),
            backgroundColor: AppColors.alertError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context
        .read<ProductProvider>()
        .categories
        .where((c) => c != 'Todos')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Agregar Producto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Imagen
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: _imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(_imagePath!),
                            fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              size: 48, color: AppColors.textDisabled),
                          const SizedBox(height: 8),
                          Text('Toca para agregar imagen',
                              style: GoogleFonts.nunito(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio (MXN)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa un precio';
                final p = double.tryParse(v.trim());
                if (p == null || p <= 0) return 'Precio inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Text('Categoría',
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            // FIX: replaced non-existent RadioGroup<String> with standard RadioListTile list
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...categories.map((cat) => RadioListTile<String>(
                      title: Text(cat,
                          style: GoogleFonts.nunito(
                              fontSize: 14, color: AppColors.textPrimary)),
                      value: cat,
                      groupValue: _useNewCategory ? null : _selectedCategory,
                      activeColor: AppColors.primary,
                      dense: true,
                      onChanged: (v) => setState(() {
                        _useNewCategory = false;
                        _selectedCategory = v;
                      }),
                    )),
                RadioListTile<String>(
                  title: Text('Nueva categoría...',
                      style: GoogleFonts.nunito(
                          fontSize: 14, color: AppColors.textPrimary)),
                  value: '__new__',
                  groupValue: _useNewCategory ? '__new__' : _selectedCategory,
                  activeColor: AppColors.primary,
                  dense: true,
                  onChanged: (_) => setState(() {
                    _useNewCategory = true;
                    _selectedCategory = null;
                  }),
                ),
              ],
            ),
            if (_useNewCategory)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: TextFormField(
                  controller: _newCategoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nueva categoría',
                    prefixIcon: Icon(Icons.add_circle_outline),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Agregar Producto'),
            ),
          ],
        ),
      ),
    );
  }
}
