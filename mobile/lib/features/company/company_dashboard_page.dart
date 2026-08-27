import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'company_bloc.dart';

class CompanyDashboardPage extends StatefulWidget {
  const CompanyDashboardPage({super.key});

  @override
  State<CompanyDashboardPage> createState() => _CompanyDashboardPageState();
}

class _CompanyDashboardPageState extends State<CompanyDashboardPage> {
  final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    context.read<CompanyBloc>().add(LoadBalance());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Kartu Saldo ──────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo Giro',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    BlocBuilder<CompanyBloc, CompanyState>(
                      builder: (context, state) {
                        // Loading
                        if (state is CompanyLoading) {
                          return const SizedBox(
                            height: 36,
                            child: Row(children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text('Memuat saldo...',
                                  style: TextStyle(color: Colors.grey)),
                            ]),
                          );
                        }

                        // Error
                        if (state is CompanyError) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  state.message,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              TextButton.icon(
                                onPressed: () => context
                                    .read<CompanyBloc>()
                                    .add(LoadBalance()),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Coba lagi'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          );
                        }

                        // Loaded
                        if (state is BalanceLoaded) {
                          return Text(
                            _rupiah.format(state.balance),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }

                        // Initial / default
                        return const Text(
                          'Rp 0',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Shortcut Menu ─────────────────────────────
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MenuCard(
                  'Transfer',
                  Icons.send,
                  () => context.push('/company/transfer'),
                ),
                _MenuCard(
                  'Riwayat',
                  Icons.history,
                  () => context.push('/company/transfer/history'),
                ),
                _MenuCard(
                  'Top-up Giro',
                  Icons.account_balance_wallet,
                  () => context.push('/company/topup'),
                ),
              ],
            ),
          ],
        ),
      );
}

// ── Menu Card Widget ──────────────────────────────────
class _MenuCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
