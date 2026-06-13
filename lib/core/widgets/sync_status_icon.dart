import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'custom_snackbar.dart';
import 'package:cloud_power_salesman/providers/sync_provider.dart';

class SyncStatusIcon extends ConsumerStatefulWidget {
  const SyncStatusIcon({super.key});

  @override
  ConsumerState<SyncStatusIcon> createState() => _SyncStatusIconState();
}

class _SyncStatusIconState extends ConsumerState<SyncStatusIcon>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    // Pulse controller for the glowing halo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Rotate controller for spinning the sync icon
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _updateAnimations(bool isSyncing) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (isSyncing) {
        if (!_pulseController.isAnimating) {
          _pulseController.repeat();
        }
        if (!_rotateController.isAnimating) {
          _rotateController.repeat();
        }
      } else {
        if (_pulseController.isAnimating) _pulseController.stop();
        if (_rotateController.isAnimating) _rotateController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);
    _updateAnimations(syncState.isSyncing);

    // Determine status color & details
    Color statusColor;
    IconData iconData;
    String statusLabel;
    final int totalPending = syncState.pendingOrders + syncState.pendingVisits;

    if (!syncState.isOnline) {
      statusColor = Colors.redAccent;
      iconData = Icons.cloud_off;
      statusLabel = "Offline - Local queue: $totalPending";
    } else if (syncState.isSyncing) {
      statusColor = Colors.orangeAccent;
      iconData = Icons.sync;
      statusLabel = "Syncing with cloud...";
    } else if (totalPending > 0) {
      statusColor = Colors.lightBlueAccent;
      iconData = Icons.sync_problem;
      statusLabel = "$totalPending pending updates (online)";
    } else {
      statusColor = Colors.greenAccent;
      iconData = Icons.cloud_done;
      statusLabel = "Fully synchronized";
    }

    return Tooltip(
      message: statusLabel,
      child: GestureDetector(
        onTap: () async {
          if (!syncState.isOnline) {
            CustomSnackbar.show(
              context,
              message: "Cannot sync while device is offline.",
              type: SnackbarType.error,
            );
            return;
          }

          CustomSnackbar.show(
            context,
            message: "Manually forcing cloud synchronization...",
            type: SnackbarType.info,
            duration: const Duration(milliseconds: 1500),
          );

          await ref.read(syncProvider.notifier).autoSync();

          if (mounted) {
            final latestState = ref.read(syncProvider);
            if (latestState.errorMessage != null) {
              CustomSnackbar.show(
                context,
                message: latestState.errorMessage!,
                type: SnackbarType.error,
              );
            } else {
              CustomSnackbar.show(
                context,
                message:
                    "Sync complete! Pending: ${latestState.pendingOrders + latestState.pendingVisits}",
                type: SnackbarType.success,
              );
            }
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glowing Halo Pulse (Only during active syncing)
            if (syncState.isSyncing)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 38 + (_pulseController.value * 14),
                    height: 38 + (_pulseController.value * 14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          statusColor.withOpacity(1.0 - _pulseController.value),
                    ),
                  );
                },
              ),

            // Inner solid background node
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.15),
              ),
            ),

            // Standard Icon display with optional Rotation
            if (syncState.isSyncing)
              AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateController.value * 2 * math.pi,
                    child: Icon(iconData, color: statusColor, size: 20),
                  );
                },
              )
            else
              Icon(iconData, color: statusColor, size: 20),

            // Badge overlay for pending records
            if (totalPending > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$totalPending',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
