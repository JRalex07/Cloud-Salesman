import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:cloud_power_salesman/models/order.dart';
import 'package:cloud_power_salesman/models/salesman.dart';
import 'package:cloud_power_salesman/models/visit.dart';
import 'package:cloud_power_salesman/core/widgets/kpi_card.dart';
import 'package:cloud_power_salesman/core/widgets/responsive_layout.dart';
import 'package:cloud_power_salesman/core/widgets/sync_status_icon.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';
import 'package:cloud_power_salesman/providers/sync_provider.dart';
import 'package:cloud_power_salesman/repositories/order_repository.dart';
import 'package:cloud_power_salesman/repositories/visit_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  Widget _buildConnectivityBanner(
      BuildContext context, WidgetRef ref, SyncState? syncState) {
    if (syncState == null) return const SizedBox.shrink();

    final int totalPending = syncState.pendingOrders + syncState.pendingVisits;
    final bool isOnline = syncState.isOnline;
    final bool isSyncing = syncState.isSyncing;

    Color bannerColor;
    Color textColor;
    IconData icon;
    String titleText;
    String subtitleText;

    if (!isOnline) {
      bannerColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
      icon = Icons.cloud_off_outlined;
      titleText = 'Offline Support Active';
      subtitleText = totalPending > 0
          ? '$totalPending entries stored securely in your local offline queue.'
          : 'App is running offline. Orders and visits will be saved locally.';
    } else if (isSyncing) {
      bannerColor = Colors.blue.shade50;
      textColor = Colors.blue.shade900;
      icon = Icons.sync;
      titleText = 'Synchronizing Logs...';
      subtitleText =
          'Updating real-time ledgers, orders, and visits with cloud databases.';
    } else if (totalPending > 0) {
      bannerColor = Colors.amber.shade50;
      textColor = Colors.amber.shade900;
      icon = Icons.sync_problem_outlined;
      titleText = 'Queue Awaiting Integration';
      subtitleText =
          '$totalPending local updates are waiting to sync with Cloud Power server.';
    } else {
      bannerColor = Colors.green.shade50;
      textColor = const Color(0xFF065F46); // green-800
      icon = Icons.cloud_done_outlined;
      titleText = 'Device Online & Synced';
      subtitleText =
          'All offline buffers are clear. Server synchronization is fully up-to-date.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: !isOnline
            ? Colors.amber.shade50
            : (totalPending > 0 ? Colors.orange.shade50 : bannerColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (!isOnline
              ? Colors.amber.shade200
              : (totalPending > 0
                  ? Colors.orange.shade200
                  : textColor.withOpacity(0.1))),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (!isOnline
                  ? Colors.amber.shade100
                  : (totalPending > 0
                      ? Colors.orange.shade100
                      : textColor.withOpacity(0.08))),
              shape: BoxShape.circle,
            ),
            child: isSyncing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                  )
                : Icon(
                    !isOnline
                        ? Icons.cloud_off
                        : (totalPending > 0 ? Icons.sync : icon),
                    color: !isOnline
                        ? Colors.amber.shade900
                        : (totalPending > 0
                            ? Colors.orange.shade900
                            : textColor),
                    size: 20,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !isOnline
                      ? 'Network Offline'
                      : (totalPending > 0
                          ? 'Synchronization Pending'
                          : titleText),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: !isOnline
                        ? Colors.amber.shade900
                        : (totalPending > 0
                            ? Colors.orange.shade900
                            : textColor),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  !isOnline
                      ? 'Entries will sync automatically when online.'
                      : subtitleText,
                  style: TextStyle(
                    fontSize: 12,
                    color: !isOnline
                        ? Colors.amber.shade800
                        : (totalPending > 0
                            ? Colors.orange.shade800
                            : textColor.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),
          if (totalPending > 0 && isOnline && !isSyncing)
            TextButton(
              onPressed: () => ref.read(syncProvider.notifier).autoSync(),
              child: const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(salesmanProfileProvider);
    final syncState = ref.watch(syncProvider);

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Loading profile failed: $err'))),
      data: (salesman) {
        if (salesman == null) {
          return const Scaffold(
              body: Center(child: Text('No active salesman profile found.')));
        }

        final bool isAdmin = salesman.role.toLowerCase() == 'admin';

        return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin
                        ? 'Admin Console: ${salesman.name}'
                        : 'Welcome, ${salesman.name}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('${salesman.assignedArea} • ${salesman.role}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
              actions: [
                const SyncStatusIcon(),
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () => context.push('/notifications'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                await ref.read(salesmanProfileProvider.notifier).refresh();
              },
              child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConnectivityBanner(context, ref, syncState),
                        isAdmin
                            ? _buildAdminDashboard(context, ref, salesman.uid)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // KPI Panel supporting adaptive bento layout grids helper
                                  ResponsiveLayout(
                                    mobile: _buildKpiGrid(ref, salesman.uid,
                                        crossAxisCount: 2, aspectRatio: 1.15),
                                    tablet: _buildKpiGrid(ref, salesman.uid,
                                        crossAxisCount: 3, aspectRatio: 1.6),
                                    desktop: _buildKpiGrid(ref, salesman.uid,
                                        crossAxisCount: 4, aspectRatio: 1.8),
                                  ),
                                  const SizedBox(height: 24),

                                  // Primary Quick Actions Grid
                                  const Text(
                                    'Quick Actions',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  GridView.count(
                                    crossAxisCount:
                                        MediaQuery.of(context).size.width >= 600
                                            ? 4
                                            : 2,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 2.2,
                                    children: [
                                      _buildActionCard(
                                        context,
                                        'Route Partners',
                                        Colors.blue,
                                        Icons.store_mall_directory_outlined,
                                        () => context.go('/shops'),
                                      ),
                                      _buildActionCard(
                                        context,
                                        'Start Visit',
                                        Colors.indigo,
                                        Icons.place_outlined,
                                        () => context.go('/visits'),
                                      ),
                                      _buildActionCard(
                                        context,
                                        'Order History',
                                        Colors.green,
                                        Icons.shopping_cart_outlined,
                                        () => context.go('/orders/history'),
                                      ),
                                      _buildActionCard(
                                        context,
                                        'Shift Records',
                                        Colors.teal,
                                        Icons.more_time_outlined,
                                        () => context.go('/attendance'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Today Completed visits list & Active Target accomplishments details
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Today Visits',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 12),
                                            StreamBuilder(
                                              stream: ref
                                                  .watch(
                                                      visitRepositoryProvider)
                                                  .getVisitsHistoryStream(
                                                      salesman.uid),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Center(
                                                      child: Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  16),
                                                          child:
                                                              CircularProgressIndicator()));
                                                }
                                                final list =
                                                    snapshot.data ?? [];
                                                if (list.isEmpty) {
                                                  return Card(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              24.0),
                                                      child: Center(
                                                        child: Text(
                                                          'No visits recorded today yet.',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .grey[500]),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return ListView.builder(
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemCount: list.length > 3
                                                      ? 3
                                                      : list.length,
                                                  itemBuilder: (context, idx) {
                                                    final visit = list[idx];
                                                    return Card(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              bottom: 8),
                                                      child: ListTile(
                                                        leading: CircleAvatar(
                                                          backgroundColor:
                                                              Colors.blue
                                                                  .withOpacity(
                                                                      0.1),
                                                          child: Icon(
                                                              Icons.location_on,
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor),
                                                        ),
                                                        title: Text(
                                                            visit.shopName,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                        subtitle: Text(visit
                                                                    .status ==
                                                                'CheckedIn'
                                                            ? 'Checked in at client desk'
                                                            : 'Visit completed'),
                                                        trailing: Chip(
                                                          label: Text(
                                                              visit.status,
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          11)),
                                                          backgroundColor: visit
                                                                      .status ==
                                                                  'Completed'
                                                              ? Colors
                                                                  .green[100]
                                                              : Colors
                                                                  .blue[100],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            )
                                          ],
                                        ),
                                      ),
                                      if (MediaQuery.of(context).size.width >=
                                          900) ...[
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: _buildRouteTargetCard(),
                                        )
                                      ]
                                    ],
                                  )
                                ],
                              ),
                      ])),
            ));
      },
    );
  }

  Widget _buildKpiGrid(WidgetRef ref, String salesmanId,
      {required int crossAxisCount, required double aspectRatio}) {
    return StreamBuilder(
      stream:
          ref.watch(orderRepositoryProvider).getOrdersBySalesman(salesmanId),
      builder: (context, snapshot) {
        // final ordersList = snapshot.data ?? [];
        // double dailySales = 0.0;
        // double monthlySales = 0.0;

        // final now = DateTime.now();
        // for (var o in ordersList) {
        //   // Today's total sales
        //   if (o.createdAt.year == now.year && o.createdAt.month == now.month && o.createdAt.day == now.day) {
        //     dailySales += o.total;
        //   }
        //   // Dynamic Monthly aggregate values
        //   if (o.createdAt.year == now.year && o.createdAt.month == now.month) {
        //     monthlySales += o.total;
        //   }
        // }
        final ordersList = snapshot.data ?? <Order>[];

        double dailySales = 0.0;
        double monthlySales = 0.0;

        final now = DateTime.now();

        for (final o in ordersList.whereType<Order>()) {
          if (o.createdAt.year == now.year &&
              o.createdAt.month == now.month &&
              o.createdAt.day == now.day) {
            dailySales += o.total;
          }

          if (o.createdAt.year == now.year && o.createdAt.month == now.month) {
            monthlySales += o.total;
          }
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            KpiCard(
              title: "Today's Booking",
              value: '₹${dailySales.toStringAsFixed(2)}',
              icon: Icons.monetization_on_outlined,
              baseColor: Colors.blue,
              // subtitle:
              //     'From ${ordersList.where((o) => o!.createdAt.day == now.day).length} order bookings today',
              subtitle:
                  'From ${ordersList.whereType<Order>().where((o) => o.createdAt.year == now.year && o.createdAt.month == now.month && o.createdAt.day == now.day).length} order bookings today',
              trendPercentage: dailySales > 0 ? 12.5 : 0.0,
            ),
            KpiCard(
              title: "Monthly Volume",
              value: '₹${monthlySales.toStringAsFixed(2)}',
              icon: Icons.analytics_outlined,
              baseColor: Colors.indigo,
              progressPercentage: (monthlySales / 8000.0)
                  .clamp(0.0, 1.0), // Target sample of 8k
              subtitle:
                  'Achievement: ${((monthlySales / 8000.0) * 100).toStringAsFixed(1)}%',
              trendPercentage: 8.2,
            ),
            // Visits Counter from visit collection
            StreamBuilder(
              stream: ref
                  .watch(visitRepositoryProvider)
                  .getVisitsHistoryStream(salesmanId),
              builder: (context, vSnapshot) {
                // final visits = vSnapshot.data ?? [];
                // final todayVisits =
                //     visits.where((v) => v.createdAt.day == now.day).toList();
                final visits = vSnapshot.data ?? <Visit>[];

                final todayVisits = visits
                    .whereType<Visit>()
                    .where((v) =>
                        v.createdAt.year == now.year &&
                        v.createdAt.month == now.month &&
                        v.createdAt.day == now.day)
                    .toList();
                final completedCount =
                    todayVisits.where((v) => v.status == 'Completed').length;

                return KpiCard(
                  title: 'Store Visits Today',
                  value: '$completedCount/${todayVisits.length}',
                  icon: Icons.directions_walk_outlined,
                  baseColor: Colors.green,
                  progressPercentage: todayVisits.isEmpty
                      ? 0
                      : (completedCount / todayVisits.length).clamp(0.0, 1.0),
                  subtitle:
                      '${todayVisits.length - completedCount} stores remaining',
                  trendPercentage: -4.5,
                );
              },
            ),
            KpiCard(
              title: 'Est. Commission',
              value: '₹${(monthlySales * 0.05).toStringAsFixed(2)}',
              icon: Icons.emoji_events_outlined,
              baseColor: Colors.orange,
              subtitle: 'Calculated at 5% volume rate',
              trendPercentage: 15.0,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: Colors.white,
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteTargetCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assigned Route Targets',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Route:'),
                Text('Metro Retail Zone A',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assigned Retailers:'),
                Text('24 Shops', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Penetration Rate:'),
                Text('82%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('FMCG Skus Delivered:'),
                Text('1,450 Units',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDashboard(
      BuildContext context, WidgetRef ref, String adminUid) {
    final firestore = ref.watch(firestoreProvider);
    final String todayDate = DateTime.now().toLocal().toString().split(' ')[0];

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('salesmen').snapshots(),
      builder: (context, salesmenSnapshot) {
        if (salesmenSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator()));
        }

        final salesmenDocs = salesmenSnapshot.data?.docs ?? [];
        final salesmen = salesmenDocs
            .map((doc) => Salesman.fromJson(doc.data()))
            .where((s) => s.role.toLowerCase() == 'salesman')
            .toList();

        final salesmanIds = salesmen.map((s) => s.uid).toList();

        return StreamBuilder<Map<String, Map<String, dynamic>>>(
          stream: _aggregateTodayAttendance(firestore, salesmanIds, todayDate),
          builder: (context, attendanceSnapshot) {
            final Map<String, Map<String, dynamic>> attendanceMap =
                attendanceSnapshot.data ?? {};

            final totalSalesmen = salesmen.length;
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);

            int loggedInTodayCount = 0;
            int onDutyCount = 0;
            int shiftCompletedCount = 0;

            for (var s in salesmen) {
              if (s.lastLogin.isAfter(todayStart)) {
                loggedInTodayCount++;
              }

              if (attendanceMap.containsKey(s.uid)) {
                final attData = attendanceMap[s.uid]!;
                final endDutyTime = attData['endDutyTime'];
                if (endDutyTime == null) {
                  onDutyCount++;
                } else {
                  shiftCompletedCount++;
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Row
                ResponsiveLayout(
                  mobile: _buildAdminKpiGrid(
                    totalLoggedToday: loggedInTodayCount,
                    totalOnDuty: onDutyCount,
                    totalCompleted: shiftCompletedCount,
                    totalRegistered: totalSalesmen,
                    crossAxisCount: 2,
                    aspectRatio: 1.15,
                  ),
                  tablet: _buildAdminKpiGrid(
                    totalLoggedToday: loggedInTodayCount,
                    totalOnDuty: onDutyCount,
                    totalCompleted: shiftCompletedCount,
                    totalRegistered: totalSalesmen,
                    crossAxisCount: 4,
                    aspectRatio: 1.6,
                  ),
                  desktop: _buildAdminKpiGrid(
                    totalLoggedToday: loggedInTodayCount,
                    totalOnDuty: onDutyCount,
                    totalCompleted: shiftCompletedCount,
                    totalRegistered: totalSalesmen,
                    crossAxisCount: 4,
                    aspectRatio: 1.8,
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions row
                const Text(
                  'Management Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount:
                      MediaQuery.of(context).size.width >= 600 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _buildActionCard(
                      context,
                      'Retail Outlets',
                      Colors.blue,
                      Icons.storefront_outlined,
                      () => context.go('/shops'),
                    ),
                    _buildActionCard(
                      context,
                      'Recent Orders',
                      Colors.green,
                      Icons.receipt_long_outlined,
                      () => context.go('/orders/history'),
                    ),
                    _buildActionCard(
                      context,
                      'Global Shifts',
                      Colors.teal,
                      Icons.badge_outlined,
                      () => context.go('/attendance'),
                    ),
                    _buildActionCard(
                      context,
                      'Force Data Refresh',
                      Colors.orange,
                      Icons.sync,
                      () =>
                          ref.read(salesmanProfileProvider.notifier).refresh(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Salesmen Directory/Stream Status Tracker
                const Text(
                  'Salesmen Live Status & Activity Tracker',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitors daily logins (updated at standard login steps) and real-time active duties.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),

                if (salesmen.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No registered salesmen in system.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: salesmen.length,
                    itemBuilder: (context, index) {
                      final s = salesmen[index];
                      final todayAttendance = attendanceMap[s.uid];

                      Color statusColor = Colors.grey;
                      String statusText = 'Off Duty';
                      String timeDetail = '';

                      final loggedInToday = s.lastLogin.isAfter(todayStart);

                      if (todayAttendance != null) {
                        final endDutyTime = todayAttendance['endDutyTime'];
                        if (endDutyTime == null) {
                          statusColor = Colors.green;
                          statusText = 'ON DUTY';
                          final start =
                              todayAttendance['startDutyTime'] as Timestamp?;
                          if (start != null) {
                            final startTimeStr = start
                                .toDate()
                                .toLocal()
                                .toString()
                                .split('.')[0]
                                .substring(11, 16);
                            timeDetail = 'Started: $startTimeStr';
                          }
                        } else {
                          statusColor = Colors.blue;
                          statusText = 'SHIFT COMPLETED';
                          final end = endDutyTime as Timestamp?;
                          final duration = todayAttendance['duration'] ?? 0;
                          if (end != null) {
                            final endTimeStr = end
                                .toDate()
                                .toLocal()
                                .toString()
                                .split('.')[0]
                                .substring(11, 16);
                            timeDetail =
                                'Checked out: $endTimeStr ($duration min)';
                          }
                        }
                      }

                      final loginTimeStr = s.lastLogin
                          .toLocal()
                          .toString()
                          .split('.')[0]
                          .substring(11, 16);
                      final loginDateStr =
                          s.lastLogin.toLocal().toString().split(' ')[0];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: loggedInToday
                                ? Colors.blue.withOpacity(0.15)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundImage: s.photoUrl.isNotEmpty
                                ? NetworkImage(s.photoUrl)
                                : null,
                            backgroundColor: loggedInToday
                                ? Colors.blue[100]
                                : Colors.grey[200],
                            child: s.photoUrl.isEmpty
                                ? Text(
                                    s.name.isNotEmpty
                                        ? s.name[0].toUpperCase()
                                        : 'S',
                                    style: TextStyle(
                                        color: loggedInToday
                                            ? Colors.blue[900]
                                            : Colors.grey[700],
                                        fontWeight: FontWeight.bold))
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              if (loggedInToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Logged In Today',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            'Area: ${s.assignedArea} • ${s.phone}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: statusColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (timeDetail.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  timeDetail,
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  _buildSalesmanInfoRow(
                                      'Email Address:', s.email),
                                  const SizedBox(height: 6),
                                  _buildSalesmanInfoRow(
                                      'Last Authentication Login:',
                                      loggedInToday
                                          ? 'Today, $loginTimeStr'
                                          : '$loginDateStr, $loginTimeStr'),
                                  const SizedBox(height: 6),
                                  _buildSalesmanInfoRow('Assigned Route Code:',
                                      s.assignedRouteId),
                                  const SizedBox(height: 6),
                                  _buildSalesmanInfoRow(
                                      'Device Push Token (FCM):',
                                      s.fcmToken.isNotEmpty
                                          ? 'Token Registered'
                                          : 'Not Connected'),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSalesmanInfoRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey)),
        Text(val,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAdminKpiGrid({
    required int totalLoggedToday,
    required int totalOnDuty,
    required int totalCompleted,
    required int totalRegistered,
    required int crossAxisCount,
    required double aspectRatio,
  }) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: aspectRatio,
      children: [
        KpiCard(
          title: "Logged In Today",
          value: '$totalLoggedToday / $totalRegistered',
          icon: Icons.login_outlined,
          baseColor: Colors.blue,
          progressPercentage: totalRegistered == 0
              ? 0
              : (totalLoggedToday / totalRegistered).clamp(0.0, 1.0),
          subtitle: 'Authentication counts',
          trendPercentage: 5.2,
        ),
        KpiCard(
          title: "Currently On Duty",
          value: '$totalOnDuty',
          icon: Icons.run_circle_outlined,
          baseColor: Colors.green,
          subtitle: 'Active routes tracked live',
          trendPercentage: totalOnDuty > 0 ? 12.0 : 0.0,
        ),
        KpiCard(
          title: "Completed Today",
          value: '$totalCompleted',
          icon: Icons.check_circle_outline,
          baseColor: Colors.green,
          subtitle: 'Ended daily duties',
          trendPercentage: 3.5,
        ),
        KpiCard(
          title: "Total Salesmen",
          value: '$totalRegistered',
          icon: Icons.people_outline,
          baseColor: Colors.indigo,
          subtitle: 'Active in directories',
          trendPercentage: 1.8,
        ),
      ],
    );
  }
}

Stream<Map<String, Map<String, dynamic>>> _aggregateTodayAttendance(
    FirebaseFirestore firestore, List<String> salesmanIds, String todayDate) {
  if (salesmanIds.isEmpty) {
    return Stream.value({});
  }

  final StreamController<Map<String, Map<String, dynamic>>> controller =
      StreamController<Map<String, Map<String, dynamic>>>.broadcast();
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      subscriptions = {};
  final Map<String, Map<String, dynamic>> latestData = {};

  void emit() {
    if (!controller.isClosed) {
      controller.add(Map.from(latestData));
    }
  }

  controller.onListen = () {
    for (final id in salesmanIds) {
      final sub = firestore
          .collection('attendance')
          .doc(todayDate)
          .collection(id)
          .snapshots()
          .listen((snap) {
        if (snap.docs.isNotEmpty) {
          latestData[id] = snap.docs.first.data();
        } else {
          latestData.remove(id);
        }
        emit();
      }, onError: (err) {
        // Ignored gracefully
      });
      subscriptions[id] = sub;
    }
  };

  controller.onCancel = () {
    for (final sub in subscriptions.values) {
      sub.cancel();
    }
    subscriptions.clear();
    controller.close();
  };

  return controller.stream;
}
