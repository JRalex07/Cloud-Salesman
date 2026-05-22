import 'package:flutter/material.dart';

import '../../../shared/models/product_model.dart';

import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductModel> products;

  const ProductGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final crossAxisCount = width > 1200
        ? 5
        : width > 900
        ? 4
        : width > 700
        ? 3
        : 2;

    return GridView.builder(
      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      itemCount: products.length,

      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,

        crossAxisSpacing: 14,

        mainAxisSpacing: 14,

        childAspectRatio: 0.72,
      ),

      itemBuilder: (context, index) {
        final product = products[index];

        return ProductCard(product: product, onTap: () {});
      },
    );
  }
}
