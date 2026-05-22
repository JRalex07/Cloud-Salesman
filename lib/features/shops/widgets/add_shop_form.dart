import 'dart:io';

import 'package:flutter/material.dart';

class AddShopForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  final TextEditingController shopNameController;

  final TextEditingController ownerNameController;

  final TextEditingController phoneController;

  final TextEditingController addressController;

  final File? image;

  final VoidCallback onPickImage;

  final VoidCallback onSubmit;

  final bool loading;

  const AddShopForm({
    super.key,
    required this.formKey,
    required this.shopNameController,
    required this.ownerNameController,
    required this.phoneController,
    required this.addressController,
    required this.image,
    required this.onPickImage,
    required this.onSubmit,
    required this.loading,
  });

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,

      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,

      child: Column(
        children: [
          GestureDetector(
            onTap: onPickImage,

            child: CircleAvatar(
              radius: 60,

              backgroundImage: image != null ? FileImage(image!) : null,

              child: image == null
                  ? const Icon(Icons.camera_alt, size: 40)
                  : null,
            ),
          ),

          const SizedBox(height: 24),

          TextFormField(
            controller: shopNameController,

            decoration: decoration("Shop Name"),

            validator: (v) {
              if (v == null || v.isEmpty) {
                return "Enter shop name";
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: ownerNameController,

            decoration: decoration("Owner Name"),

            validator: (v) {
              if (v == null || v.isEmpty) {
                return "Enter owner name";
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: phoneController,

            keyboardType: TextInputType.phone,

            decoration: decoration("Phone Number"),

            validator: (v) {
              if (v == null || v.length < 10) {
                return "Invalid phone";
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: addressController,

            maxLines: 3,

            decoration: decoration("Address"),

            validator: (v) {
              if (v == null || v.isEmpty) {
                return "Enter address";
              }

              return null;
            },
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,

            height: 56,

            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,

              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("ADD SHOP"),
            ),
          ),
        ],
      ),
    );
  }
}
