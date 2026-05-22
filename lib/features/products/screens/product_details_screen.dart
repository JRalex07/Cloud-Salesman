import 'package:flutter/material.dart';

import '../../../shared/models/product_model.dart';

import '../../../core/widgets/network_image_widget.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            NetworkImageWidget(
              imageUrl: product.image,

              height: 300,

              width: double.infinity,
            ),

            Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    product.name,

                    style: const TextStyle(
                      fontSize: 28,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(product.description),

                  const SizedBox(height: 24),

                  Text(
                    "Wholesale Price: ₹${product.wholesalePrice}",

                    style: const TextStyle(
                      fontSize: 18,

                      color: Colors.green,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text("Retail Price: ₹${product.retailPrice}"),

                  const SizedBox(height: 10),

                  Text("Stock: ${product.stock}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
