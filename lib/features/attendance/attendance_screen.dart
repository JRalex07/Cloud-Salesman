import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_power_salesman/core/widgets/custom_snackbar.dart';
import 'package:cloud_power_salesman/models/attendance.dart';
import 'package:cloud_power_salesman/repositories/attendance_repository.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  Attendance? _todayAttendance;
  bool _isLoadingToday = true;
  bool _isActioningShift = false;

  @override
  void initState() {
    super.initState();
    _checkTodayShiftStatus();
  }

  Future<void> _checkTodayShiftStatus() async {
    final salesman = ref.read(salesmanProfileProvider).valueOrNull;
    if (salesman == null) return;

    setState(() {
      _isLoadingToday = true;
    });

    try {
      final String todayDate =
          DateTime.now().toLocal().toString().split(' ')[0];
      final att = await ref
          .read(attendanceRepositoryProvider)
          .getTodayAttendance(salesman.uid, todayDate);
      if (mounted) {
        setState(() {
          _todayAttendance = att;
          _isLoadingToday = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingToday = false;
        });
      }
    }
  }

  Future<void> _startShift() async {
    final salesman = ref.read(salesmanProfileProvider).valueOrNull;
    if (salesman == null) return;

    setState(() {
      _isActioningShift = true;
    });

    try {
      final String uid = salesman.uid;
      final String todayDate =
          DateTime.now().toLocal().toString().split(' ')[0];
      final String uniqueId = 'ATT-${DateTime.now().millisecondsSinceEpoch}';

      final attendance = Attendance(
        attendanceId: uniqueId,
        startDutyTime: DateTime.now(),
        duration: 0,
        date: todayDate,
        status: 'Present',
        startLatitude:
            40.7128, // capture direct latitude coordinates representatively
        startLongitude: -74.0060,
        endLatitude: 0.0,
        endLongitude: 0.0,
      );

      await ref.read(attendanceRepositoryProvider).startDuty(uid, attendance);
      await _checkTodayShiftStatus();
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Duty shift started successfully!',
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Failed to start duty shift: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActioningShift = false;
        });
      }
    }
  }

  Future<void> _endShift() async {
    final salesman = ref.read(salesmanProfileProvider).valueOrNull;
    if (salesman == null || _todayAttendance == null) return;

    setState(() {
      _isActioningShift = true;
    });

    try {
      await ref.read(attendanceRepositoryProvider).endDuty(
            salesman.uid,
            _todayAttendance!.attendanceId,
            DateTime.now(),
            40.7180, // capture final exit latitude representatively
            -74.0090,
          );
      await _checkTodayShiftStatus();
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Duty shift ended successfully!',
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Failed to end duty shift: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActioningShift = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesman = ref.watch(salesmanProfileProvider).valueOrNull;

    if (salesman == null) {
      return const Scaffold(body: Center(child: Text('Session missing.')));
    }

    final activeOnDuty =
        _todayAttendance != null && _todayAttendance!.endDutyTime == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift & Attendance'),
      ),
      body: _isLoadingToday
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShiftControlCard(activeOnDuty),
                  const SizedBox(height: 24),
                  const Text('Past Work Attendance Sheets',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildAttendanceHistorySection(salesman.uid),
                ],
              ),
            ),
    );
  }

  Widget _buildShiftControlCard(bool activeOnDuty) {
    final Color cardBg =
        activeOnDuty ? Colors.green[50]! : Colors.blueGrey[50]!;
    final Color iconCol = activeOnDuty ? Colors.green : Colors.blueGrey;

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.badge, color: iconCol, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeOnDuty
                            ? 'On Duty Shift: ACTIVE'
                            : 'Shift: NOT STARTED',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: iconCol),
                      ),
                      const SizedBox(height: 4),
                      if (activeOnDuty)
                        Text(
                          'Started at: ${_todayAttendance!.startDutyTime?.toLocal().toString().split('.')[0].substring(11, 16) ?? ''}',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 13),
                        )
                      else
                        Text('Book routes and log client drop offsets.',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeOnDuty
                      ? Colors.red[800]
                      : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isActioningShift
                    ? null
                    : (activeOnDuty ? _endShift : _startShift),
                child: _isActioningShift
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        activeOnDuty
                            ? 'Click to End Duty Shift'
                            : 'Click to Register & Start Duty',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceHistorySection(String salesmanId) {
    final stream = ref
        .read(attendanceRepositoryProvider)
        .getAttendanceHistoryStream(salesmanId);

    return StreamBuilder<List<Attendance>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('No historical duty attendance logs tracked yet.',
                  style: TextStyle(color: Colors.grey[400])),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, idx) {
            final a = list[idx];
            final ended = a.endDutyTime != null;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(a.date,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  ended
                      ? 'Duration: ${a.duration} mins • ${a.startDutyTime?.toLocal().toString().split(' ')[1].substring(0, 5) ?? ''} to ${a.endDutyTime?.toLocal().toString().split(' ')[1].substring(0, 5) ?? ''}'
                      : 'Duty In-progress...',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                trailing: Chip(
                  label: Text(a.status,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: ended ? Colors.green[800] : Colors.blue[800])),
                  backgroundColor: ended ? Colors.green[50] : Colors.blue[50],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
