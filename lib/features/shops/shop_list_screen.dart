import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/shop.dart';
import '../../repositories/shop_repository.dart';

class ShopListScreen extends ConsumerStatefulWidget {
  const ShopListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends ConsumerState<ShopListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Shop> _searchedShops = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _triggerSearch(String val) async {
    if (val.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchedShops = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _searchQuery = val;
      _isSearching = true;
    });

    try {
      final results = await ref.read(shopRepositoryProvider).searchShops(val);
      setState(() {
        _searchedShops = results;
        _isSearching = false;
      });
    } catch (_) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Stores & Shops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Register New Shop',
            onPressed: () => context.go('/shops/add'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Elegant integrated search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _triggerSearch,
              decoration: InputDecoration(
                hintText: 'Search shops by client name or store name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _triggerSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResultsList()
                : _buildFullStreamList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchedShops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No stores matched your query.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchedShops.length,
      itemBuilder: (context, idx) {
        return _buildShopCard(_searchedShops[idx]);
      },
    );
  }

  Widget _buildFullStreamList() {
    final stream = ref.watch(shopRepositoryProvider).getShopsStream();

    return StreamBuilder<List<Shop>>(
      stream: stream,
      builder: (context, sn) {
        if (sn.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = sn.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront, size: 50, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No retailers registered in system yet.',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => context.go('/shops/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Shop Now'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: list.length,
          itemBuilder: (context, idx) {
            return _buildShopCard(list[idx]);
          },
        );
      },
    );
  }

  Widget _buildShopCard(Shop shop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/shops/${shop.shopId}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: shop.imageUrl.isNotEmpty
                    ? Image.network(
                        shop.imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
                      )
                    : _buildFallbackAvatar(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.shopName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contact: ${shop.shopkeeperName}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.pin_drop,
                          size: 14,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shop.address,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (shop.approved)
                const Icon(Icons.verified, color: Colors.blue, size: 20)
              else
                Icon(Icons.pending_actions, color: Colors.amber[700], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey[100],
      child: const Icon(Icons.storefront, color: Colors.grey),
    );
  }
}
