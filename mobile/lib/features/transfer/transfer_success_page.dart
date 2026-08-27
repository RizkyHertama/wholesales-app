import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_button.dart';

class TransferSuccessPage extends StatelessWidget {
  const TransferSuccessPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF0E9F6E), size: 80),
            const SizedBox(height: 20),
            const Text('Transfer Berhasil!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            AppButton(
              label: 'Kembali ke Dashboard',
              onPressed: () => context.go('/company/dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}
