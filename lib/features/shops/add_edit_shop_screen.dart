import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_power_salesman/core/widgets/custom_snackbar.dart';
import 'package:cloud_power_salesman/core/widgets/custom_button.dart';
import 'package:cloud_power_salesman/core/widgets/custom_text_field.dart';
import 'package:cloud_power_salesman/models/shop.dart';
import 'package:cloud_power_salesman/repositories/shop_repository.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';

class AddEditShopScreen extends ConsumerStatefulWidget {
  const AddEditShopScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddEditShopScreen> createState() => _AddEditShopScreenState();
}

class _AddEditShopScreenState extends ConsumerState<AddEditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _keeperController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _routeController = TextEditingController();
  final _notesController = TextEditingController();

  // GPS States
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _gpsCaptured = false;
  bool _capturingGps = false;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _keeperController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _routeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _captureGpsCoordinates() async {
    setState(() {
      _capturingGps = true;
    });

    // Simulate high-fidelity cellular GPS capture hook
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() {
        _latitude = 40.7128 +
            (0.01 *
                (DateTime.now().second %
                    10)); // Simulated realistic local offsets
        _longitude = -74.0060 + (0.01 * (DateTime.now().second % 10));
        _gpsCaptured = true;
        _capturingGps = false;
      });
    }
  }

  Future<void> _handleSaveShop() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_gpsCaptured) {
      CustomSnackbar.show(
        context,
        message: 'Please capture shop GPS coordinates first for route validation.',
        type: SnackbarType.warning,
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final currentSalesman = ref.read(salesmanProfileProvider).valueOrNull;
      final String secureShopId =
          'SHP-${DateTime.now().millisecondsSinceEpoch}';

      final newShop = Shop(
        shopId: secureShopId,
        shopName: _nameController.text.trim(),
        shopkeeperName: _keeperController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim().isNotEmpty
            ? _whatsappController.text.trim()
            : _phoneController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        salesmanId: currentSalesman?.uid ?? '',
        routeId: _routeController.text.trim().isNotEmpty
            ? _routeController.text.trim()
            : 'Route-01',
        area: _areaController.text.trim().isNotEmpty
            ? _areaController.text.trim()
            : 'Metro Hub',
        imageUrl:
            '', // Blank initially or handled via image uploads in production
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        approved:
            false, // Standard admin authorization loops trigger approvals
        active: true,
      );

      await ref.read(shopRepositoryProvider).addShop(newShop);

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Store partner added successfully!',
          type: SnackbarType.success,
        );
        context.pop(); // Returns safely to the shop listings screen
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSaving = false;
        });
        CustomSnackbar.show(
          context,
          message: 'Failed to add store: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Store Partner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Register Outlet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Provide accurate retailer descriptions and ensure you are standing at the outlet entrance before hitting GPS Capture.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                  child: Text(_errorMessage!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              CustomTextField(
                label: 'Shop Name *',
                placeholder: "e.g. Metro Grocery Store",
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? 'Shop name is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Shopkeeper / Client Name *',
                placeholder: 'e.g. Alex Henderson',
                controller: _keeperController,
                validator: (v) => v == null || v.isEmpty ? 'Client name is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Contact Phone Number *',
                placeholder: '+1 (555) 019-2834',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'WhatsApp Number (Optional)',
                placeholder: 'Defaults to Contact Number if blank',
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Physical Address *',
                placeholder: 'Street, Building, landmark details',
                controller: _addressController,
                validator: (v) => v == null || v.isEmpty ? 'Store address is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Area / Subzone',
                      placeholder: 'Metro A',
                      controller: _areaController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Assigned Route Code',
                      placeholder: 'Route-12',
                      controller: _routeController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Field Observations & Notes',
                placeholder: 'Store constraints, off-peak times, specific GST requests...',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // GPS capturing panel
              Card(
                color: _gpsCaptured ? Colors.green[50] : Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _gpsCaptured ? Icons.check_circle : Icons.gps_fixed,
                        color: _gpsCaptured ? Colors.green : Colors.amber[800],
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Field Coordinates Capture *', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            if (_gpsCaptured)
                              Text(
                                'Lat: ${_latitude.toStringAsFixed(6)}\nLng: ${_longitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                              )
                            else if (_capturingGps)
                              const Text('Verifying satellites coordinates...', style: TextStyle(fontSize: 12, color: Colors.blueGrey))
                            else
                              const Text('GPS not captured. Move outside for exact tracking.', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gpsCaptured ? Colors.green : Theme.of(context).primaryColor,
                        ),
                        onPressed: _capturingGps ? null : _captureGpsCoordinates,
                        child: _capturingGps
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_gpsCaptured ? 'Recapture' : 'Capture'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              CustomButton(
                text: 'Save & Submit Store',
                isLoading: _isSaving,
                onPressed: _handleSaveShop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

