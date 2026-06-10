// lib/screens/admin/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/product_image.dart';
import '../../widgets/slide_fade_in.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _perSizePricing = false;

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Control de Inventario'),
        actions: [
          IconButton(
            icon: Icon(
                _perSizePricing ? Icons.monetization_on : Icons.attach_money),
            tooltip: _perSizePricing ? 'Precio por talla' : 'Precio general',
            onPressed: () => setState(() => _perSizePricing = !_perSizePricing),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => products.fetchProducts(),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Agregar producto',
            onPressed: () => context.push(AppRoutes.addProduct),
          ),
        ],
      ),
      body: products.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : products.products.isEmpty
              ? Center(
                  child: Text('Sin productos en el catálogo.',
                      style:
                          GoogleFonts.nunito(color: AppColors.textSecondary)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => SlideFadeIn(
                    index: i,
                    child: _ProductStockCard(
                        product: products.products[i],
                        perSizePricing: _perSizePricing),
                  ),
                ),
    );
  }
}

class _ProductStockCard extends StatefulWidget {
  final Product product;
  final bool perSizePricing;
  const _ProductStockCard({required this.product, this.perSizePricing = false});

  @override
  State<_ProductStockCard> createState() => _ProductStockCardState();
}

class _ProductStockCardState extends State<_ProductStockCard> {
  bool get hasCritical =>
      Product.standardSizes.any((s) => widget.product.isLowStock(s));

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      await context
          .read<ProductProvider>()
          .updateProductImage(widget.product.id, picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCritical
              ? AppColors.alertStock.withValues(alpha: 0.5)
              : AppColors.border,
          width: hasCritical ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: ProductImage(imageUrl: widget.product.imageUrl),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.category.toUpperCase(),
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                              letterSpacing: 1.2)),
                      Text(widget.product.name,
                          style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showEditPricesDialog(context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            widget.perSizePricing
                                ? 'Precio variable'
                                : formatMxn(widget.product.price),
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary)),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit,
                            size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  onSelected: (v) {
                    if (v == 'edit') _showEditProductDialog(context);
                    if (v == 'delete') _showDeleteConfirmDialog(context);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Editar producto')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Eliminar producto')),
                  ],
                ),
              ],
            ),
          ),
          if (hasCritical)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.alertStock.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: AppColors.alertStock),
                  const SizedBox(width: 6),
                  Text('Stock crítico en una o más tallas (≤3 unidades)',
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.alertStock)),
                ]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Product.standardSizes.map((size) {
                final stock = widget.product.stockForSize(size);
                return _SizeBadge(
                  size: size,
                  stock: stock,
                  price: widget.product.priceForSize(size),
                  showPrice: widget.perSizePricing,
                  isLow: widget.product.isLowStock(size),
                  isOut: stock == 0,
                  onTap: () =>
                      _showAdjustDialog(context, widget.product, size, stock),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPricesDialog(BuildContext context) {
    // FIX: capture outer context before dialog opens
    final outerCtx = context;
    final priceBySize = <String, TextEditingController>{};
    for (final size in Product.standardSizes) {
      priceBySize[size] = TextEditingController(
        text: widget.product.priceForSize(size).toStringAsFixed(2),
      );
    }
    final basePriceCtrl = TextEditingController(
      text: widget.product.price.toStringAsFixed(2),
    );

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Precios: ${widget.product.name}',
            style:
                GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Precio base (sin talla específica)',
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: basePriceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Precio base (MXN)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Precios por talla (opcional)',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              ...Product.standardSizes.map((size) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: priceBySize[size]!,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Talla $size (MXN)',
                        prefixIcon: const Icon(Icons.straighten),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // FIX: pop dialog first, then dispose
              Navigator.pop(dialogCtx);
              for (final c in priceBySize.values) c.dispose();
              basePriceCtrl.dispose();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // FIX: snapshot all values BEFORE disposing or popping
              final newBasePrice = double.tryParse(basePriceCtrl.text.trim());
              final priceUpdates = <String, double>{};
              if (newBasePrice != null &&
                  newBasePrice != widget.product.price &&
                  newBasePrice >= 0) {
                priceUpdates['base'] = newBasePrice;
              }
              for (final size in Product.standardSizes) {
                final newSizePrice =
                    double.tryParse(priceBySize[size]!.text.trim());
                if (newSizePrice != null &&
                    newSizePrice != widget.product.priceForSize(size) &&
                    newSizePrice >= 0) {
                  priceUpdates['size_$size'] = newSizePrice;
                }
              }
              // FIX: read provider from outerCtx, not dialogCtx
              final prov = outerCtx.read<ProductProvider>();
              Navigator.pop(dialogCtx);
              for (final c in priceBySize.values) c.dispose();
              basePriceCtrl.dispose();

              try {
                if (priceUpdates.containsKey('base')) {
                  await prov.updateProductPrice(
                      widget.product.id, priceUpdates['base']!);
                }
                for (final size in Product.standardSizes) {
                  if (priceUpdates.containsKey('size_$size')) {
                    await prov.updateProductPriceForSize(
                        widget.product.id, size, priceUpdates['size_$size']!);
                  }
                }
              } catch (e) {
                if (outerCtx.mounted) {
                  ScaffoldMessenger.of(outerCtx).showSnackBar(SnackBar(
                    content: Text('Error al actualizar precio: $e'),
                    backgroundColor: AppColors.alertError,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(
      BuildContext context, Product product, String size, int current) {
    final outerCtx = context;
    final ctrl = TextEditingController(text: '$current');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Ajustar stock: ${product.name}',
            style:
                GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Talla $size · Stock actual: $current',
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Nuevo stock',
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ctrl.dispose();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // FIX: snapshot value before dispose/pop
              final newStock = int.tryParse(ctrl.text.trim());
              // FIX: read from outerCtx
              final prov = outerCtx.read<ProductProvider>();
              Navigator.pop(dialogCtx);
              ctrl.dispose();
              try {
                if (newStock != null && newStock != current && newStock >= 0) {
                  await prov.setStock(product.id, size, newStock);
                }
              } catch (e) {
                if (outerCtx.mounted) {
                  ScaffoldMessenger.of(outerCtx).showSnackBar(SnackBar(
                    content: Text('Error al actualizar stock: $e'),
                    backgroundColor: AppColors.alertError,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(BuildContext context) {
    final outerCtx = context;
    final nameCtrl = TextEditingController(text: widget.product.name);
    final priceCtrl =
        TextEditingController(text: widget.product.price.toStringAsFixed(2));
    final descCtrl = TextEditingController(text: widget.product.description);
    // FIX: RadioGroup<String> does NOT exist in Flutter — replaced with StatefulBuilder + local state
    final cats = context
        .read<ProductProvider>()
        .categories
        .where((c) => c != 'Todos')
        .toList();
    String selectedCategory = widget.product.category;
    bool useNewCategory = false;
    final newCategoryCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar producto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Precio (MXN)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Categoría',
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                // FIX: replaced RadioGroup (non-existent widget) with standard RadioListTile list
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...cats.map((cat) => RadioListTile<String>(
                          title: Text(cat,
                              style: GoogleFonts.nunito(
                                  fontSize: 14, color: AppColors.textPrimary)),
                          value: cat,
                          groupValue: useNewCategory ? '' : selectedCategory,
                          activeColor: AppColors.primary,
                          dense: true,
                          onChanged: (v) => setDialogState(() {
                            useNewCategory = false;
                            selectedCategory = v!;
                          }),
                        )),
                    RadioListTile<String>(
                      title: Text('Otra categoría...',
                          style: GoogleFonts.nunito(
                              fontSize: 14, color: AppColors.textPrimary)),
                      value: '',
                      groupValue: useNewCategory ? '' : selectedCategory,
                      activeColor: AppColors.primary,
                      dense: true,
                      onChanged: (_) => setDialogState(() {
                        useNewCategory = true;
                        selectedCategory = '';
                      }),
                    ),
                  ],
                ),
                if (useNewCategory)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: TextField(
                      controller: newCategoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nueva categoría',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                nameCtrl.dispose();
                priceCtrl.dispose();
                descCtrl.dispose();
                newCategoryCtrl.dispose();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final newPrice = double.tryParse(priceCtrl.text.trim());
                final newDesc = descCtrl.text.trim();
                final category = useNewCategory
                    ? newCategoryCtrl.text.trim()
                    : selectedCategory;

                if (newName.isEmpty || newPrice == null || newPrice < 0) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(const SnackBar(
                    content: Text('Nombre inválido o precio inválido'),
                    backgroundColor: AppColors.alertError,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                if (category.isEmpty) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(const SnackBar(
                    content: Text('Selecciona o escribe una categoría'),
                    backgroundColor: AppColors.alertError,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }

                // FIX: snapshot all values, read provider from outerCtx, then pop+dispose
                final prov = outerCtx.read<ProductProvider>();
                Navigator.pop(dialogCtx);
                nameCtrl.dispose();
                priceCtrl.dispose();
                descCtrl.dispose();
                newCategoryCtrl.dispose();

                try {
                  await prov.updateProduct(
                    widget.product.id,
                    name: newName,
                    category: category,
                    price: newPrice,
                    description: newDesc,
                    priceBySize: widget.product.priceBySize,
                  );
                } catch (e) {
                  if (outerCtx.mounted) {
                    ScaffoldMessenger.of(outerCtx).showSnackBar(SnackBar(
                      content: Text('Error al actualizar: $e'),
                      backgroundColor: AppColors.alertError,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    final outerCtx = context;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar producto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        content: Text(
          '¿Eliminar "${widget.product.name}"?\n\n'
          'Esta acción no se puede deshacer.',
          style:
              GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // FIX: read from outerCtx, pop with dialogCtx
              final prov = outerCtx.read<ProductProvider>();
              Navigator.pop(dialogCtx);
              try {
                await prov.deleteProduct(widget.product.id);
              } catch (e) {
                if (outerCtx.mounted) {
                  ScaffoldMessenger.of(outerCtx).showSnackBar(SnackBar(
                    content: Text('Error al eliminar: $e'),
                    backgroundColor: AppColors.alertError,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.alertError),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _SizeBadge extends StatelessWidget {
  final String size;
  final int stock;
  final double price;
  final bool isLow, isOut;
  final bool showPrice;
  final VoidCallback onTap;

  const _SizeBadge({
    required this.size,
    required this.stock,
    required this.price,
    required this.isLow,
    required this.isOut,
    required this.onTap,
    this.showPrice = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isOut
        ? AppColors.surfaceVariant
        : isLow
            ? AppColors.alertStock.withValues(alpha: 0.10)
            : AppColors.secondary.withValues(alpha: 0.10);
    final border = isOut
        ? AppColors.border
        : isLow
            ? AppColors.alertStock
            : AppColors.secondary;
    final text = isOut
        ? AppColors.textDisabled
        : isLow
            ? AppColors.alertStock
            : AppColors.secondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(size,
                style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w800, color: text)),
            const SizedBox(height: 2),
            if (showPrice && !isOut)
              Text(formatMxn(price),
                  style: GoogleFonts.nunito(
                      fontSize: 9, fontWeight: FontWeight.w800, color: text)),
            if (!showPrice)
              Text(isOut ? 'Agotado' : '$stock uds.',
                  style: GoogleFonts.nunito(
                      fontSize: 10, fontWeight: FontWeight.w700, color: text)),
            if (isLow && !isOut)
              const Icon(Icons.warning_amber_rounded,
                  size: 12, color: AppColors.alertStock),
          ],
        ),
      ),
    );
  }
}
