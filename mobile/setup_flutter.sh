#!/bin/bash

# ============================================================
#  Wholesales Flutter Project Setup Script
#  Jalankan dari dalam folder mobile/ setelah flutter create
#  Usage: bash setup_flutter.sh
# ============================================================

set -e
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[CREATE]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC}   $1"; }

ROOT="lib"

# ─────────────────────────────────────────────
# 1. BUAT SEMUA FOLDER
# ─────────────────────────────────────────────
info "Membuat folder structure..."

mkdir -p $ROOT/core/{api,router,storage,theme}
mkdir -p $ROOT/features/{auth,company,transfer,admin}
mkdir -p $ROOT/shared/widgets

# ─────────────────────────────────────────────
# 2. HELPER: buat file dengan konten
# ─────────────────────────────────────────────
make_file() {
  local path=$1
  local content=$2
  echo "$content" > "$path"
  log "$path"
}

# ─────────────────────────────────────────────
# 3. CORE FILES
# ─────────────────────────────────────────────
info "Membuat core files..."

make_file "$ROOT/core/api/endpoints.dart" \
"class ApiEndpoints {
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android emulator

  // Auth
  static const String login    = '/api/auth/login';
  static const String register = '/api/auth/register';

  // Company
  static const String balance = '/api/company/balance';
  static const String topup   = '/api/company/topup';

  // Transfer
  static const String transfer        = '/api/transfer';
  static const String transferHistory = '/api/transfer/history';

  // Admin
  static const String employees = '/api/admin/employees';
  static const String companies = '/api/admin/companies';
}"

make_file "$ROOT/core/api/dio_client.dart" \
"import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'endpoints.dart';

class DioClient {
  late final Dio dio;

  DioClient(SecureStorage storage) {
    dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer \$token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await storage.clear();
        }
        handler.next(error);
      },
    ));
  }
}"

make_file "$ROOT/core/storage/secure_storage.dart" \
"import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final _storage = const FlutterSecureStorage();

  static const _token = 'jwt_token';
  static const _role  = 'user_role';

  Future<void> saveToken(String token) => _storage.write(key: _token, value: token);
  Future<String?> getToken()           => _storage.read(key: _token);
  Future<void> saveRole(String role)   => _storage.write(key: _role, value: role);
  Future<String?> getRole()            => _storage.read(key: _role);
  Future<void> clear()                 => _storage.deleteAll();
}"

make_file "$ROOT/core/router/app_router.dart" \
"import 'package:go_router/go_router.dart';
import '../../features/auth/splash_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/company/company_dashboard_page.dart';
import '../../features/company/topup_giro_page.dart';
import '../../features/transfer/transfer_page.dart';
import '../../features/transfer/transfer_confirm_page.dart';
import '../../features/transfer/transfer_success_page.dart';
import '../../features/transfer/transfer_history_page.dart';
import '../../features/admin/admin_dashboard_page.dart';
import '../../features/admin/employee_list_page.dart';
import '../../features/admin/company_list_page.dart';
import '../storage/secure_storage.dart';

class AppRouter {
  static GoRouter router(SecureStorage storage) => GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final token = await storage.getToken();
      final role  = await storage.getRole();
      final loc   = state.matchedLocation;

      if (token == null && loc != '/login' && loc != '/register') {
        return '/login';
      }
      if (loc == '/' && token != null) {
        return role == 'admin' ? '/admin/dashboard' : '/company/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/',         builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login',    builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),

      GoRoute(path: '/company/dashboard', builder: (_, __) => const CompanyDashboardPage()),
      GoRoute(path: '/company/topup',     builder: (_, __) => const TopupGiroPage()),

      GoRoute(path: '/company/transfer',         builder: (_, __) => const TransferPage()),
      GoRoute(path: '/company/transfer/confirm', builder: (_, s) => TransferConfirmPage(data: s.extra as Map<String, dynamic>? ?? {})),
      GoRoute(path: '/company/transfer/success', builder: (_, __) => const TransferSuccessPage()),
      GoRoute(path: '/company/transfer/history', builder: (_, __) => const TransferHistoryPage()),

      GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardPage()),
      GoRoute(path: '/admin/employees', builder: (_, __) => const EmployeeListPage()),
      GoRoute(path: '/admin/companies', builder: (_, __) => const CompanyListPage()),
    ],
  );
}"

make_file "$ROOT/core/theme/app_theme.dart" \
"import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary   = Color(0xFF1A56DB);
  static const Color secondary = Color(0xFF0E9F6E);
  static const Color error     = Color(0xFFE02424);
  static const Color bg        = Color(0xFFF9FAFB);

  static ThemeData get light => ThemeData(
    colorSchemeSeed: primary,
    scaffoldBackgroundColor: bg,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF111827),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}"

# ─────────────────────────────────────────────
# 4. SHARED WIDGETS
# ─────────────────────────────────────────────
info "Membuat shared widgets..."

make_file "$ROOT/shared/widgets/app_button.dart" \
"import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    child: isLoading
        ? const SizedBox(height: 20, width: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  );
}"

make_file "$ROOT/shared/widgets/app_text_field.dart" \
"import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool obscure;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.obscure = false,
    this.controller,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(labelText: label, hintText: hint),
  );
}"

make_file "$ROOT/shared/widgets/error_text.dart" \
"import 'package:flutter/material.dart';

class ErrorText extends StatelessWidget {
  final String message;
  const ErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFDE8E8),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFFE02424))),
  );
}"

# ─────────────────────────────────────────────
# 5. AUTH FEATURE
# ─────────────────────────────────────────────
info "Membuat auth feature..."

make_file "$ROOT/features/auth/auth_repository.dart" \
"import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/storage/secure_storage.dart';

class AuthRepository {
  final DioClient _client;
  final SecureStorage _storage;

  AuthRepository(this._client, this._storage);

  Future<String> login(String email, String password) async {
    final res = await _client.dio.post(ApiEndpoints.login,
        data: {'email': email, 'password': password});
    final token = res.data['token'] as String;
    final role  = res.data['role'] as String? ?? 'company';
    await _storage.saveToken(token);
    await _storage.saveRole(role);
    return role;
  }

  Future<void> register(String companyName, String email, String password) async {
    await _client.dio.post(ApiEndpoints.register,
        data: {'company_name': companyName, 'email': email, 'password': password});
  }

  Future<void> logout() => _storage.clear();
}"

make_file "$ROOT/features/auth/auth_bloc.dart" \
"import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_repository.dart';

// ── Events ──
abstract class AuthEvent {}
class LoginRequested    extends AuthEvent { final String email, password; LoginRequested(this.email, this.password); }
class RegisterRequested extends AuthEvent { final String name, email, password; RegisterRequested(this.name, this.email, this.password); }
class LogoutRequested   extends AuthEvent {}

// ── States ──
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState { final String role; AuthSuccess(this.role); }
class AuthFailure extends AuthState { final String message; AuthFailure(this.message); }
class AuthLoggedOut extends AuthState {}

// ── Bloc ──
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    on<LoginRequested>((e, emit) async {
      emit(AuthLoading());
      try {
        final role = await _repo.login(e.email, e.password);
        emit(AuthSuccess(role));
      } catch (err) {
        emit(AuthFailure(_parseError(err)));
      }
    });

    on<RegisterRequested>((e, emit) async {
      emit(AuthLoading());
      try {
        await _repo.register(e.name, e.email, e.password);
        emit(AuthSuccess('company'));
      } catch (err) {
        emit(AuthFailure(_parseError(err)));
      }
    });

    on<LogoutRequested>((e, emit) async {
      await _repo.logout();
      emit(AuthLoggedOut());
    });
  }

  String _parseError(dynamic err) {
    if (err is Exception) return err.toString().replaceAll('Exception: ', '');
    return 'Terjadi kesalahan';
  }
}"

make_file "$ROOT/features/auth/splash_page.dart" \
"import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/secure_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    // GoRouter redirect akan handle navigasi berdasarkan token
    context.go('/');
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}"

make_file "$ROOT/features/auth/login_page.dart" \
"import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/error_text.dart';
import 'auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          state.role == 'admin'
              ? context.go('/admin/dashboard')
              : context.go('/company/dashboard');
        }
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text('Masuk', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Masuk ke akun perusahaan Anda',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Email wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _passCtrl,
                  obscure: true,
                  validator: (v) => v!.isEmpty ? 'Password wajib diisi' : null,
                ),
                const SizedBox(height: 24),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        if (state is AuthFailure) ...[
                          ErrorText(state.message),
                          const SizedBox(height: 16),
                        ],
                        AppButton(
                          label: 'Masuk',
                          isLoading: state is AuthLoading,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthBloc>().add(
                                LoginRequested(_emailCtrl.text, _passCtrl.text));
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Belum punya akun? Daftar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}"

make_file "$ROOT/features/auth/register_page.dart" \
"import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/error_text.dart';
import 'auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl= TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Daftar Perusahaan')),
    body: BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) context.go('/company/dashboard');
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                AppTextField(
                  label: 'Nama Perusahaan',
                  controller: _nameCtrl,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _passCtrl,
                  obscure: true,
                  validator: (v) => v!.length < 6 ? 'Minimal 6 karakter' : null,
                ),
                const SizedBox(height: 24),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) => Column(
                    children: [
                      if (state is AuthFailure) ...[
                        ErrorText(state.message),
                        const SizedBox(height: 16),
                      ],
                      AppButton(
                        label: 'Daftar',
                        isLoading: state is AuthLoading,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(RegisterRequested(
                              _nameCtrl.text, _emailCtrl.text, _passCtrl.text));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}"

# ─────────────────────────────────────────────
# 6. COMPANY FEATURE (placeholder pages)
# ─────────────────────────────────────────────
info "Membuat company feature..."

make_file "$ROOT/features/company/company_repository.dart" \
"import '../../core/api/dio_client.dart';
import '../../core/api/endpoints.dart';

class CompanyRepository {
  final DioClient _client;
  CompanyRepository(this._client);

  Future<Map<String, dynamic>> getBalance() async {
    final res = await _client.dio.get(ApiEndpoints.balance);
    return res.data as Map<String, dynamic>;
  }

  Future<void> topupGiro(double amount) async {
    await _client.dio.post(ApiEndpoints.topup, data: {'amount': amount});
  }
}"

make_file "$ROOT/features/company/company_bloc.dart" \
"import 'package:flutter_bloc/flutter_bloc.dart';
import 'company_repository.dart';

abstract class CompanyEvent {}
class LoadBalance extends CompanyEvent {}
class TopupRequested extends CompanyEvent { final double amount; TopupRequested(this.amount); }

abstract class CompanyState {}
class CompanyInitial extends CompanyState {}
class CompanyLoading extends CompanyState {}
class CompanyLoaded  extends CompanyState { final Map<String, dynamic> data; CompanyLoaded(this.data); }
class CompanyError   extends CompanyState { final String message; CompanyError(this.message); }
class TopupSuccess   extends CompanyState {}

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  final CompanyRepository _repo;

  CompanyBloc(this._repo) : super(CompanyInitial()) {
    on<LoadBalance>((e, emit) async {
      emit(CompanyLoading());
      try {
        final data = await _repo.getBalance();
        emit(CompanyLoaded(data));
      } catch (err) {
        emit(CompanyError(err.toString()));
      }
    });

    on<TopupRequested>((e, emit) async {
      emit(CompanyLoading());
      try {
        await _repo.topupGiro(e.amount);
        emit(TopupSuccess());
      } catch (err) {
        emit(CompanyError(err.toString()));
      }
    });
  }
}"

make_file "$ROOT/features/company/company_dashboard_page.dart" \
"import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyDashboardPage extends StatelessWidget {
  const CompanyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dashboard')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // TODO: Tampilkan saldo
        Card(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Saldo Giro', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            const Text('Rp 0', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ]),
        )),
        const SizedBox(height: 20),
        // Shortcut menu
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MenuCard('Transfer', Icons.send, () => context.push('/company/transfer')),
            _MenuCard('Riwayat', Icons.history, () => context.push('/company/transfer/history')),
            _MenuCard('Top-up Giro', Icons.account_balance_wallet, () => context.push('/company/topup')),
          ],
        ),
      ],
    ),
  );
}

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
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}"

make_file "$ROOT/features/company/topup_giro_page.dart" \
"import 'package:flutter/material.dart';

class TopupGiroPage extends StatelessWidget {
  const TopupGiroPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Top-up Giro')),
    body: const Center(child: Text('TODO: Form top-up giro')),
  );
}"

# ─────────────────────────────────────────────
# 7. TRANSFER FEATURE (placeholder pages)
# ─────────────────────────────────────────────
info "Membuat transfer feature..."

make_file "$ROOT/features/transfer/transfer_repository.dart" \
"import '../../core/api/dio_client.dart';
import '../../core/api/endpoints.dart';

class TransferRepository {
  final DioClient _client;
  TransferRepository(this._client);

  Future<void> createTransfer(Map<String, dynamic> payload) async {
    await _client.dio.post(ApiEndpoints.transfer, data: payload);
  }

  Future<List<dynamic>> getHistory() async {
    final res = await _client.dio.get(ApiEndpoints.transferHistory);
    return res.data as List<dynamic>;
  }
}"

make_file "$ROOT/features/transfer/transfer_bloc.dart" \
"import 'package:flutter_bloc/flutter_bloc.dart';
import 'transfer_repository.dart';

abstract class TransferEvent {}
class SubmitTransfer   extends TransferEvent { final Map<String, dynamic> data; SubmitTransfer(this.data); }
class LoadHistory      extends TransferEvent {}

abstract class TransferState {}
class TransferInitial  extends TransferState {}
class TransferLoading  extends TransferState {}
class TransferSuccess  extends TransferState {}
class TransferFailure  extends TransferState { final String message; TransferFailure(this.message); }
class HistoryLoaded    extends TransferState { final List<dynamic> items; HistoryLoaded(this.items); }

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final TransferRepository _repo;

  TransferBloc(this._repo) : super(TransferInitial()) {
    on<SubmitTransfer>((e, emit) async {
      emit(TransferLoading());
      try {
        await _repo.createTransfer(e.data);
        emit(TransferSuccess());
      } catch (err) {
        emit(TransferFailure(err.toString()));
      }
    });

    on<LoadHistory>((e, emit) async {
      emit(TransferLoading());
      try {
        final items = await _repo.getHistory();
        emit(HistoryLoaded(items));
      } catch (err) {
        emit(TransferFailure(err.toString()));
      }
    });
  }
}"

make_file "$ROOT/features/transfer/transfer_page.dart" \
"import 'package:flutter/material.dart';
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
            title: Text(item.\$1, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(item.\$2),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/company/transfer/confirm',
                extra: {'type': item.\$1}),
          ),
        )),
      ],
    ),
  );
}"

make_file "$ROOT/features/transfer/transfer_confirm_page.dart" \
"import 'package:flutter/material.dart';
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
          Text('Jenis: \${data['type'] ?? '-'}'),
          const Spacer(),
          AppButton(
            label: 'Konfirmasi & Kirim',
            onPressed: () => context.pushReplacement('/company/transfer/success'),
          ),
        ],
      ),
    ),
  );
}"

make_file "$ROOT/features/transfer/transfer_success_page.dart" \
"import 'package:flutter/material.dart';
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
}"

make_file "$ROOT/features/transfer/transfer_history_page.dart" \
"import 'package:flutter/material.dart';

class TransferHistoryPage extends StatelessWidget {
  const TransferHistoryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Riwayat Transfer')),
    body: const Center(child: Text('TODO: List riwayat transfer')),
  );
}"

# ─────────────────────────────────────────────
# 8. ADMIN FEATURE (placeholder pages)
# ─────────────────────────────────────────────
info "Membuat admin feature..."

make_file "$ROOT/features/admin/admin_repository.dart" \
"import '../../core/api/dio_client.dart';
import '../../core/api/endpoints.dart';

class AdminRepository {
  final DioClient _client;
  AdminRepository(this._client);

  Future<List<dynamic>> getEmployees() async {
    final res = await _client.dio.get(ApiEndpoints.employees);
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getCompanies() async {
    final res = await _client.dio.get(ApiEndpoints.companies);
    return res.data as List<dynamic>;
  }
}"

make_file "$ROOT/features/admin/admin_bloc.dart" \
"import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_repository.dart';

abstract class AdminEvent {}
class LoadEmployees extends AdminEvent {}
class LoadCompanies extends AdminEvent {}

abstract class AdminState {}
class AdminInitial  extends AdminState {}
class AdminLoading  extends AdminState {}
class AdminLoaded   extends AdminState { final List<dynamic> items; AdminLoaded(this.items); }
class AdminError    extends AdminState { final String message; AdminError(this.message); }

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repo;

  AdminBloc(this._repo) : super(AdminInitial()) {
    on<LoadEmployees>((e, emit) async {
      emit(AdminLoading());
      try { emit(AdminLoaded(await _repo.getEmployees())); }
      catch (err) { emit(AdminError(err.toString())); }
    });

    on<LoadCompanies>((e, emit) async {
      emit(AdminLoading());
      try { emit(AdminLoaded(await _repo.getCompanies())); }
      catch (err) { emit(AdminError(err.toString())); }
    });
  }
}"

make_file "$ROOT/features/admin/admin_dashboard_page.dart" \
"import 'package:flutter/material.dart';
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
}"

make_file "$ROOT/features/admin/employee_list_page.dart" \
"import 'package:flutter/material.dart';

class EmployeeListPage extends StatelessWidget {
  const EmployeeListPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Daftar Karyawan')),
    body: const Center(child: Text('TODO: List karyawan dari API')),
  );
}"

make_file "$ROOT/features/admin/company_list_page.dart" \
"import 'package:flutter/material.dart';

class CompanyListPage extends StatelessWidget {
  const CompanyListPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perusahaan Terdaftar')),
    body: const Center(child: Text('TODO: List perusahaan dari API')),
  );
}"

# ─────────────────────────────────────────────
# 9. main.dart & app.dart
# ─────────────────────────────────────────────
info "Membuat main.dart dan app.dart..."

make_file "$ROOT/main.dart" \
"import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WholesalesApp());
}"

make_file "$ROOT/app.dart" \
"import 'package:flutter/material.dart';
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
    final storage  = SecureStorage();
    final client   = DioClient(storage);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(AuthRepository(client, storage))),
        BlocProvider(create: (_) => CompanyBloc(CompanyRepository(client))),
        BlocProvider(create: (_) => TransferBloc(TransferRepository(client))),
        BlocProvider(create: (_) => AdminBloc(AdminRepository(client))),
      ],
      child: MaterialApp.router(
        title: 'Wholesales App',
        theme: AppTheme.light,
        routerConfig: AppRouter.router(storage),
      ),
    );
  }
}"

# ─────────────────────────────────────────────
# 10. SELESAI
# ─────────────────────────────────────────────
echo ""
echo -e "${GREEN}======================================"
echo -e " Setup selesai!"
echo -e "======================================${NC}"
echo ""
echo "File yang dibuat:"
find $ROOT -type f -name "*.dart" | sort
echo ""
echo "Langkah selanjutnya:"
echo "  1. Tambahkan dependencies di pubspec.yaml"
echo "  2. Jalankan: flutter pub get"
echo "  3. Jalankan: flutter run"
echo ""