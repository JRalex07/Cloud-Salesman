import 'package:flutter/material.dart';

import '../data/visit_repository.dart';

import '../widgets/visit_card.dart';

class VisitHistoryScreen extends StatelessWidget {
  const VisitHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = VisitRepository();

    return Scaffold(
      appBar: AppBar(title: const Text("Visit History")),

      body: StreamBuilder(
        stream: repository.getVisits(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final visits = snapshot.data!;

          if (visits.isEmpty) {
            return const Center(child: Text("No visits found"));
          }

          return ListView.builder(
            itemCount: visits.length,

            itemBuilder: (context, index) {
              return VisitCard(visit: visits[index]);
            },
          );
        },
      ),
    );
  }
}
