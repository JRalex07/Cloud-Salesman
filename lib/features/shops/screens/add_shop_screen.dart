import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import 'package:uuid/uuid.dart';

import '../../../core/services/location_service.dart';

import '../../../core/services/storage_service.dart';

import '../../../shared/models/shop_model.dart';

import '../data/shop_repository.dart';

import '../widgets/add_shop_form.dart';

class AddShopScreen extends StatefulWidget {
  const AddShopScreen({super.key});

  @override
  State<AddShopScreen> createState() => _AddShopScreenState();
}

class _AddShopScreenState extends State<AddShopScreen> {
  final formKey = GlobalKey<FormState>();

  final shopNameController = TextEditingController();

  final ownerNameController = TextEditingController();

  final phoneController = TextEditingController();

  final addressController = TextEditingController();

  final picker = ImagePicker();

  final repository = ShopRepository();

  final storageService = StorageService();

  File? image;

  bool loading = false;

  // =========================
  // PICK IMAGE
  // =========================

  Future<void> pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,

      imageQuality: 70,
    );

    if (picked == null) return;

    setState(() {
      image = File(picked.path);
    });
  }

  // =========================
  // SUBMIT
  // =========================

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add shop image")));

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // duplicate check

      final exists = await repository.shopExists(phoneController.text.trim());

      if (exists) {
        throw Exception("Shop already exists");
      }

      // location

      final position = await LocationService().getCurrentLocation();

      // upload image

      final imageUrl = await storageService.uploadFile(
        file: image!,

        path: "shops/${const Uuid().v4()}.jpg",
      );

      final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

      final shopId = const Uuid().v4();

      final shop = ShopModel(
        id: shopId,

        shopName: shopNameController.text.trim(),

        ownerName: ownerNameController.text.trim(),

        phone: phoneController.text.trim(),

        address: addressController.text.trim(),

        latitude: position.latitude,

        longitude: position.longitude,

        createdBy: uid,

        createdAt: DateTime.now(),

        approved: false,
        image: imageUrl,
      );

      await repository.addShop(shop: shop);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Shop added successfully")),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Shop")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: AddShopForm(
          formKey: formKey,

          shopNameController: shopNameController,

          ownerNameController: ownerNameController,

          phoneController: phoneController,

          addressController: addressController,

          image: image,

          onPickImage: pickImage,

          onSubmit: submit,

          loading: loading,
        ),
      ),
    );
  }
}
