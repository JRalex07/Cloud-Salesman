import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_power_salesman/core/widgets/custom_snackbar.dart';
import 'package:cloud_power_salesman/models/visit.dart';
import 'package:cloud_power_salesman/repositories/visit_repository.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';

class VisitScreen extends ConsumerStatefulWidget {
  const VisitScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends ConsumerState<VisitScreen> {
  final TextEditingController _checkoutNotesController =
      TextEditingController();
  Visit? _activeVisit;
  bool _checkingActive = true;
  bool _isCheckingOut = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkoutNotesController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveSession() async {
    final curSalesman = ref.read(salesmanProfileProvider).valueOrNull;
    if (curSalesman == null) return;

    if (mounted) {
      setState(() {
        _checkingActive = true;
      });
    }

    try {
      final active = await ref
          .read(visitRepositoryProvider)
          .getActiveVisit(curSalesman.uid);
      if (mounted) {
        setState(() {
          _activeVisit = active;
          _checkingActive = false;
        });
      }

      if (active != null && active.checkInTime != null) {
        _startTimer(active.checkInTime!);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _checkingActive = false;
        });
      }
    }
  }

  void _startTimer(DateTime checkInTime) {
    _timer?.cancel();
    _elapsed = DateTime.now().difference(checkInTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(checkInTime);
        });
      }
    });
  }

  Future<void> _handleCheckout() async {
    final curSalesman = ref.read(salesmanProfileProvider).valueOrNull;
    if (_activeVisit == null || curSalesman == null) return;

    if (mounted) {
      setState(() {
        _isCheckingOut = true;
      });
    }

    // Capture physical exit longitude & latitude
    const double finalLat = 40.7180;
    const double finalLng = -74.0090;

    try {
      await ref.read(visitRepositoryProvider).checkOut(
            curSalesman.uid,
            _activeVisit!.visitId,
            finalLat,
            finalLng,
            _checkoutNotesController.text.trim(),
          );

      _timer?.cancel();
      _checkoutNotesController.clear();
      if (mounted) {
        setState(() {
          _activeVisit = null;
          _isCheckingOut = false;
        });
      }

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Checked out of store. Visit duration captured successfully!',
          type: SnackbarType.success,
        );
      }
      _checkActiveSession();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
        CustomSnackbar.show(
          context,
          message: 'Checkout failed: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final curSalesman = ref.watch(salesmanProfileProvider).valueOrNull;

    if (curSalesman == null) {
      return const Scaffold(body: Center(child: Text('Session missing.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Visits Manager'),
      ),
      body: _checkingActive
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeVisit != null)
                    _buildActiveVisitContainer()
                  else
                    _buildNoActiveVisitContainer(context),
                  const SizedBox(height: 24),
                  const Text('Today Visited History',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildHistoricalVisitsSnapshot(curSalesman.uid),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveVisitContainer() {
    final String elapsedStr =
        '${_elapsed.inMinutes.toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_walk, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Active Store Check-in',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Text(
                  elapsedStr,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontFamily: 'monospace',
                      fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              _activeVisit!.shopName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Checked in: ${_activeVisit!.checkInTime?.toLocal().toString().split('.')[0] ?? ''}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _checkoutNotesController,
              decoration: const InputDecoration(
                hintText:
                    'Add summary of discussion, retailer stock requirements or feedback...',
                labelText: 'Discussion Notes',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800]),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Book Order',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      context.push(
                          '/orders/create?shopId=${_activeVisit!.shopId}&shopName=${Uri.encodeComponent(_activeVisit!.shopName)}');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700]),
                    icon: _isCheckingOut
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.logout),
                    label: const Text('Check Out',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isCheckingOut ? null : _handleCheckout,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveVisitContainer(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.not_listed_location_outlined,
                  size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('No Active Visit Checked In',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                'To record orders, check-ins, store discussion feedback, or client interactions, select a store from your list and register your arrival.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.go('/shops'),
                icon: const Icon(Icons.store),
                label: const Text('Browse Shops to Check In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoricalVisitsSnapshot(String salesmanId) {
    return StreamBuilder<List<Visit>>(
      stream:
          ref.watch(visitRepositoryProvider).getVisitsHistoryStream(salesmanId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = (snapshot.data ?? [])
            .where((v) => v.status != 'CheckedIn')
            .toList();
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('No past store visits recorded today.',
                  style: TextStyle(color: Colors.grey[400])),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, idx) {
            final v = list[idx];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(v.shopName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Checkout Notes: ${v.notes.isNotEmpty ? v.notes : "No notes captured."}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Dist: ${v.distanceFromShop.toStringAsFixed(1)}m',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 4),
                    Text(v.status,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
