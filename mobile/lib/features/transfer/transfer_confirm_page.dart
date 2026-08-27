import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_button.dart';

class TransferConfirmPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const TransferConfirmPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Konfirmasi Transfer')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO: Tampilkan ringkasan transfer dari data
          Text('Jenis: ${data['type'] ?? '-'}'),
          const Spacer(),
          AppButton(
            label: 'Konfirmasi & Kirim',
            onPressed: () => context.pushReplacement('/company/transfer/success'),
          ),
        ],
      ),
    ),
  );
}
