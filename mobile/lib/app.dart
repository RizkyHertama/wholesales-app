import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/api/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_bloc.dart';
import 'features/auth/auth_repository.dart';
import 'features/company/company_bloc.dart';
import 'features/company/company_repository.dart';
import 'features/transfer/transfer_bloc.dart';
import 'features/transfer/transfer_repository.dart';
import 'features/admin/admin_bloc.dart';
import 'features/admin/admin_repository.dart';

class WholesalesApp extends StatelessWidget {
  const WholesalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Setup dependencies
    final storage = SecureStorage();
    final client = DioClient(storage);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(AuthRepository(client, storage))),
        BlocProvider(create: (_) => TransferBloc(TransferRepository(client))),
        BlocProvider(create: (_) => AdminBloc(AdminRepository(client))),
        BlocProvider(
          create: (_) => CompanyBloc(
              CompanyRepository(client, storage)), // ← tambah storage
        ),
      ],
      child: MaterialApp.router(
        title: 'Wholesales App',
        theme: AppTheme.light,
        routerConfig: AppRouter.router(storage),
      ),
    );
  }
}
