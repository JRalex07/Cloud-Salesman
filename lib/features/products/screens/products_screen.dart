import 'package:flutter/material.dart';

import '../data/product_repository.dart';

import '../widgets/product_grid.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ProductRepository();

    return Scaffold(
      appBar: AppBar(title: const Text("Products")),

      body: StreamBuilder(
        stream: repository.getProducts(),

        builder: (context, snapshot) {
          // =======================
          // LOADING
          // =======================

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!;

          // =======================
          // EMPTY
          // =======================

          if (products.isEmpty) {
            return const Center(child: Text("No products found"));
          }

          // =======================
          // PRODUCTS
          // =======================

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: ProductGrid(products: products),
          );
        },
      ),
    );
  }
}
