import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Transfer')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Pilih Jenis Transfer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...[
          ('BI FAST',   'Transfer real-time antar bank'),
          ('RTGS',      'Transfer nominal besar'),
          ('Internal',  'Transfer antar rekening Anda'),
          ('External',  'Transfer ke bank lain'),
        ].map((item) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(item.$2),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/company/transfer/confirm',
                extra: {'type': item.$1}),
          ),
        )),
      ],
    ),
  );
}
