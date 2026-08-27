import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Dashboard')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('Daftar Karyawan'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/admin/employees'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.business),
          title: const Text('Perusahaan Terdaftar'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/admin/companies'),
        ),
      ],
    ),
  );
}
