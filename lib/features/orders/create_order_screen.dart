import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_power_salesman/core/widgets/custom_snackbar.dart';
import 'package:cloud_power_salesman/models/product.dart';
import 'package:cloud_power_salesman/models/category.dart';
import 'package:cloud_power_salesman/repositories/product_repository.dart';
import 'package:cloud_power_salesman/providers/cart_provider.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  final String shopId;
  final String shopName;

  const CreateOrderScreen({
    Key? key,
    required this.shopId,
    required this.shopName,
  }) : super(key: key);

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final productsStream = ref.read(productRepositoryProvider).getActiveProducts();
    final categoriesStream = ref.read(productRepositoryProvider).getCategories();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Book Order Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Buying for: ${widget.shopName}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          Badge(
            label: Text('${cartState.itemQuantities.values.fold(0, (sum, q) => sum + q)}'),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              tooltip: 'Go to Cart',
              onPressed: () {
                context.push('/orders/cart?shopId=${widget.shopId}&shopName=${Uri.encodeComponent(widget.shopName)}');
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<Category>>(
        stream: categoriesStream,
        builder: (context, categoriesSnapshot) {
          final categoriesList = categoriesSnapshot.data ?? [];

          return StreamBuilder<List<Product>>(
            stream: productsStream,
            builder: (context, productsSnapshot) {
              if (categoriesSnapshot.connectionState == ConnectionState.waiting ||
                  productsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allProducts = productsSnapshot.data ?? [];

              // Compute categories: start with All, then load from real Firestore Categories
              final List<String> categories = ['All'];
              if (categoriesList.isNotEmpty) {
                categories.addAll(categoriesList.map((c) => c.name));
              } else {
                // Fallback dynamically from products if categories collection is empty/loading
                final uniqueCategories = allProducts
                    .map((p) => p.category)
                    .where((c) => c.trim().isNotEmpty)
                    .toSet()
                    .toList();
                uniqueCategories.sort();
                categories.addAll(uniqueCategories);
              }

              // Compute effective selected class ensuring safety if category gets removed
              final effectiveCategory = categories.contains(_selectedCategory) ? _selectedCategory : 'All';

              var filteredList = allProducts;
              if (effectiveCategory != 'All') {
                filteredList = filteredList.where((p) => p.category == effectiveCategory).toList();
              }

              return Row(
                children: [
                  // Elegant category side selector sidebar
                  Container(
                    width: 110,
                    color: Colors.grey[100],
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, idx) {
                        final cat = categories[idx];
                        final isSelected = effectiveCategory == cat;

                        // Find the corresponding Category object to get its direct link/image safely
                        final catObj = categoriesList.firstWhere(
                          (c) => c.name == cat,
                          orElse: () => Category(
                            categoryId: '',
                            name: cat,
                            image: '',
                            isActive: true,
                            priority: 99,
                            slug: '',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                            color: isSelected ? Colors.white : Colors.transparent,
                            child: Column(
                              children: [
                                catObj.image.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: catObj.image,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: Center(
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Icon(
                                            _getCategoryIcon(cat),
                                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                                            size: 24,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        _getCategoryIcon(cat),
                                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                                        size: 24,
                                      ),
                                const SizedBox(height: 6),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),

                  Expanded(
                    child: _buildFilteredProductsList(filteredList),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilteredProductsList(List<Product> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No active products in this category.', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    final cartNotifier = ref.read(cartProvider.notifier);
    final cartState = ref.watch(cartProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final p = list[idx];
        final quantity = cartState.itemQuantities[p.productId] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: p.image.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: p.image,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.fastfood, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.fastfood, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Price: ₹${p.wholesalePrice.toStringAsFixed(2)}  •  GST: ${p.gst}%', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('Available Stock: ${p.stock}', style: TextStyle(fontSize: 11, color: p.stock < 10 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                quantity > 0
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                            onPressed: () {
                              cartNotifier.updateQuantity(p.productId, quantity - 1);
                            },
                          ),
                          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                            onPressed: () {
                              if (quantity >= p.stock) {
                                CustomSnackbar.show(
                                  context,
                                  message: 'Cannot book order beyond stock capabilities.',
                                  type: SnackbarType.warning,
                                );
                                return;
                              }
                              cartNotifier.updateQuantity(p.productId, quantity + 1);
                            },
                          ),
                        ],
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: p.stock <= 0
                            ? null
                            : () {
                                cartNotifier.addItem(p);
                              },
                        child: const Text('Add', style: TextStyle(fontSize: 12)),
                      )
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Beverages':
        return Icons.local_drink_outlined;
      case 'Snacks':
        return Icons.cookie_outlined;
      case 'Dairies':
        return Icons.egg_outlined;
      case 'Household':
        return Icons.dry_cleaning_outlined;
      case 'Confectionery':
        return Icons.cake_outlined;
      default:
        return Icons.widgets_outlined;
    }
  }
}

