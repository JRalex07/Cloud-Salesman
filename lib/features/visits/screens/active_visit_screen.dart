import 'package:flutter/material.dart';

import '../data/visit_repository.dart';

import '../widgets/checkout_button.dart';

class ActiveVisitScreen extends StatelessWidget {
  const ActiveVisitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = VisitRepository();

    return Scaffold(
      appBar: AppBar(title: const Text("Active Visit")),

      body: StreamBuilder(
        stream: repository.activeVisit(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text("No Active Visit"));
          }

          final visit = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Column(
                    children: [
                      Text(
                        visit.shopName,

                        style: const TextStyle(
                          fontSize: 26,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "Checked In At",

                        style: TextStyle(color: Colors.grey.shade700),
                      ),

                      const SizedBox(height: 8),

                      Text(visit.checkInTime.toString()),
                    ],
                  ),
                ),

                const Spacer(),

                CheckOutButton(
                  onTap: () async {
                    await repository.checkOut(visit.id);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Checked out successfully"),
                        ),
                      );
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
