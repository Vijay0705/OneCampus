import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../models/product_model.dart';
import '../../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedCategory = 'All';

  static const _categories = [
    'All', 'Electronics', 'Books', 'Furniture',
    'Clothing', 'Sports', 'Stationery', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketplaceProvider>().fetchProducts();
      context.read<MarketplaceProvider>().fetchMyProducts();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MarketplaceProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.storefront_outlined), text: 'Browse'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'My Listings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _showAddProductSheet(context),
            tooltip: 'List Item',
          ),
        ],
      ),
      body: Column(
        children: [
          if (mp.errorMessage != null)
            ErrorBanner(message: mp.errorMessage!, onDismiss: mp.clearMessages),
          if (mp.successMessage != null)
            SuccessBanner(message: mp.successMessage!, onDismiss: mp.clearMessages),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _BrowseTab(
                  mp: mp,
                  selectedCategory: _selectedCategory,
                  categories: _categories,
                  onCategoryChanged: (c) =>
                      setState(() => _selectedCategory = c),
                ),
                _MyListingsTab(mp: mp),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductSheet(context),
        icon: const Icon(Icons.sell_rounded),
        label: const Text('Sell Item'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<MarketplaceProvider>(),
        child: const _AddProductSheet(),
      ),
    );
  }
}

// ── Browse Tab ────────────────────────────────────────────────────
class _BrowseTab extends StatelessWidget {
  final MarketplaceProvider mp;
  final String selectedCategory;
  final List<String> categories;
  final void Function(String) onCategoryChanged;

  const _BrowseTab({
    required this.mp,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final products = mp.products
        .where((p) =>
            selectedCategory == 'All' || p.category == selectedCategory)
        .where((p) => !p.isSold)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 0, 8),
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final selected = cat == selectedCategory;
                return ChoiceChip(
                  label: Text(_categoryEmoji(cat) + ' $cat'),
                  selected: selected,
                  onSelected: (_) => onCategoryChanged(cat),
                  selectedColor: cs.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            '${products.length} item${products.length == 1 ? '' : 's'} available',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),

        Expanded(
          child: mp.loading
              ? Center(child: CircularProgressIndicator(color: cs.primary))
              : products.isEmpty
                  ? const EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'No items found',
                      subtitle: 'Try a different category or check back later',
                    )
                  : RefreshIndicator(
                      onRefresh: mp.fetchProducts,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: products.length,
                        itemBuilder: (_, i) => _ProductCard(product: products[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}

String _categoryEmoji(String cat) {
  switch (cat) {
    case 'Electronics': return '📱';
    case 'Books': return '📚';
    case 'Furniture': return '🪑';
    case 'Clothing': return '👕';
    case 'Sports': return '⚽';
    case 'Stationery': return '✏️';
    case 'All': return '🛒';
    default: return '📦';
  }
}

Color _categoryColor(String cat) {
  switch (cat) {
    case 'Electronics': return const Color(0xFF4F46E5);
    case 'Books': return const Color(0xFF22C55E);
    case 'Furniture': return const Color(0xFFF59E0B);
    case 'Clothing': return const Color(0xFFEC4899);
    case 'Sports': return const Color(0xFF3B82F6);
    case 'Stationery': return const Color(0xFF8B5CF6);
    default: return const Color(0xFF64748B);
  }
}

// ── Product Card ──────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catColor = _categoryColor(product.category);

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showProductDetail(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                        )
                      : _PlaceholderImage(catColor: catColor, product: product),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: cs.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_categoryEmoji(product.category)} ${product.category}',
                              style: TextStyle(
                                fontSize: 10,
                                color: catColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: cs.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Chat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProductDetailSheet(product: product),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final Color catColor;
  final Product product;
  const _PlaceholderImage({required this.catColor, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: catColor.withOpacity(0.1),
      child: Center(
        child: Text(
          _categoryEmoji(product.category),
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}

// ── Product Detail Sheet ──────────────────────────────
class _ProductDetailSheet extends StatelessWidget {
  final Product product;
  const _ProductDetailSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catColor = _categoryColor(product.category);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: product.imageUrl.isNotEmpty
                    ? Image.network(product.imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: catColor.withOpacity(0.12),
                        child: Center(
                          child: Text(
                            _categoryEmoji(product.category),
                            style: const TextStyle(fontSize: 64),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_categoryEmoji(product.category)} ${product.category}',
                    style: TextStyle(
                        color: catColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                if (product.condition.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.condition,
                      style: TextStyle(
                          color: cs.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                color: cs.primary,
              ),
            ),
            if (product.description.isNotEmpty) ...
              [
                const SizedBox(height: 14),
                Text(
                  'Description',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description,
                  style: TextStyle(
                      color: cs.onSurfaceVariant,
                      height: 1.6,
                      fontSize: 14),
                ),
              ],
            const SizedBox(height: 20),
            // Seller info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_rounded,
                        color: cs.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seller',
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                        Text(
                          product.sellerName.isNotEmpty
                              ? product.sellerName
                              : 'Campus Seller',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.message_rounded),
                  label: const Text('Chat'),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Chat with ${product.sellerName.isNotEmpty ? product.sellerName : "seller"} — coming soon!'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('Contact'),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Contact feature coming soon!')),
                    );
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Add Product Sheet ──────────────────────────────────
class _AddProductSheet extends StatefulWidget {
  const _AddProductSheet();

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = 'Books';
  String _condition = 'like-new';
  Uint8List? _imageBytes;
  String? _imageName;
  bool _uploading = false;

  static const _categories = [
    'Electronics', 'Books', 'Furniture',
    'Clothing', 'Sports', 'Stationery', 'Other',
  ];
  static const _conditions = ['new', 'like-new', 'used', 'poor'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _uploading = true);
    final mp = context.read<MarketplaceProvider>();
    final ok = await mp.addProduct(
      name: _nameCtrl.text.trim(),
      price: double.parse(_priceCtrl.text),
      description: _descCtrl.text.trim(),
      category: _category,
      condition: _condition,
      imageBytes: _imageBytes,
      imageName: _imageName,
    );
    setState(() => _uploading = false);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item listed successfully! 🎉')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                children: [
                  Text('List an Item',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: cs.onSurface)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: cs.outline.withOpacity(0.4),
                              style: BorderStyle.solid,
                              width: 1),
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(_imageBytes!,
                                        fit: BoxFit.cover),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          '✏️ Change',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded,
                                      size: 40, color: cs.primary),
                                  const SizedBox(height: 8),
                                  Text('Add Photo',
                                      style: TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w600)),
                                  Text('Tap to upload from gallery',
                                      style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        prefixIcon: Icon(Icons.sell_rounded),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.notes_rounded),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price (₹)',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Text('Category',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final sel = cat == _category;
                        return ChoiceChip(
                          label: Text(
                              '${_categoryEmoji(cat)} $cat',
                              style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                          selected: sel,
                          selectedColor: cs.primary,
                          onSelected: (_) =>
                              setState(() => _category = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    Text('Condition',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _conditions.map((cond) {
                        final sel = cond == _condition;
                        return ChoiceChip(
                          label: Text(cond,
                              style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                          selected: sel,
                          selectedColor: cs.secondary,
                          onSelected: (_) =>
                              setState(() => _condition = cond),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _uploading ? null : _submit,
                        child: _uploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Text('List Item'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Listings Tab ──────────────────────────────────────
class _MyListingsTab extends StatelessWidget {
  final MarketplaceProvider mp;
  const _MyListingsTab({required this.mp});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (mp.loading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }

    if (mp.myProducts.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No Listings Yet',
        subtitle: 'Tap "Sell Item" to list something on the marketplace',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mp.myProducts.length,
      itemBuilder: (_, i) {
        final p = mp.myProducts[i];
        final catColor = _categoryColor(p.category);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: p.imageUrl.isNotEmpty
                        ? Image.network(p.imageUrl, fit: BoxFit.cover)
                        : Container(
                            color: catColor.withOpacity(0.12),
                            child: Center(
                              child: Text(_categoryEmoji(p.category),
                                  style: const TextStyle(fontSize: 32)),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: cs.onSurface),
                            ),
                          ),
                          StatusChip(
                            label: p.isSold ? 'SOLD' : 'ACTIVE',
                            color: p.isSold
                                ? cs.onSurfaceVariant
                                : cs.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${p.price.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (!p.isSold)
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                    textStyle:
                                        const TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  final ok = await mp.markAsSold(p.id);
                                  if (ok && context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Marked as sold! 💰')));
                                  }
                                },
                                child: const Text('Mark Sold'),
                              ),
                            ),
                          if (!p.isSold) const SizedBox(width: 8),
                          SizedBox(
                            height: 36,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.error,
                                side: BorderSide(
                                    color: cs.error.withOpacity(0.4)),
                                minimumSize: const Size(0, 36),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete listing?'),
                                    content: const Text(
                                        'This action cannot be undone.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(
                                              context, false),
                                          child: const Text('Cancel')),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor: cs.error),
                                        onPressed: () => Navigator.pop(
                                            context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) await mp.deleteProduct(p.id);
                              },
                              child: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}