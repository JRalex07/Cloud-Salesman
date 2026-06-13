import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_power_salesman/repositories/auth_repository.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(salesmanProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Operator Profile'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
        data: (salesman) {
          if (salesman == null) {
            return const Center(child: Text('Profile offline. Session missing.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text(
                          salesman.name.substring(0, 2).toUpperCase(),
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        salesman.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        salesman.email,
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(salesman.role, style: const TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.blue[50],
                        labelStyle: TextStyle(color: Colors.blue[800]),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                Card(
                  child: Column(
                    children: [
                      _buildProfileRow(Icons.phone, 'Contact Phone', salesman.phone),
                      const Divider(height: 1),
                      _buildProfileRow(Icons.add_road, 'Assigned Route ID', salesman.assignedRouteId),
                      const Divider(height: 1),
                      _buildProfileRow(Icons.map, 'Assigned Area Subzone', salesman.assignedArea),
                      const Divider(height: 1),
                      _buildProfileRow(Icons.cloud_done, 'Operator Status', salesman.isActive ? 'Active & On Duty' : 'Deactivated'),
                      const Divider(height: 1),
                      _buildProfileRow(
                        Icons.history,
                        'Last Login Event',
                        salesman.lastLogin.toLocal().toString().split('.')[0],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[200]!),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out profile session', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.normal)),
      trailing: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}

