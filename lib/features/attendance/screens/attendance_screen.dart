import 'package:flutter/material.dart';

import '../data/attendance_repository.dart';

import '../widgets/duty_toggle_button.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AttendanceRepository();

    return Scaffold(
      appBar: AppBar(title: const Text("Duty Status")),

      body: StreamBuilder(
        stream: repository.activeDuty(),

        builder: (context, snapshot) {
          final duty = snapshot.data;

          final active = duty != null;

          return Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(20),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),

                        blurRadius: 10,

                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      Icon(
                        active ? Icons.verified_user : Icons.pause_circle,

                        size: 72,

                        color: active ? Colors.green : Colors.grey,
                      ),

                      const SizedBox(height: 18),

                      Text(
                        active ? "Duty Active" : "Duty Not Started",

                        style: const TextStyle(
                          fontSize: 26,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (active)
                        Text(
                          "Started at:\n${duty.startDuty}",

                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),

                const Spacer(),

                DutyToggleButton(
                  active: active,

                  onTap: () async {
                    try {
                      if (active) {
                        await repository.endDuty(duty.id);
                      } else {
                        await repository.startDuty();
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              active ? "Duty ended" : "Duty started",
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
