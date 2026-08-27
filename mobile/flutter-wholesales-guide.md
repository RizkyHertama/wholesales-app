# Flutter Mobile App — Wholesales App
## Complete Step-by-Step Guide

---

## TAHAP 1 — Setup Project Flutter

### 1.1 Buat Project Baru

```bash
# Masuk ke folder monorepo kamu
cd wholesales-app/

# Buat flutter project di folder mobile
flutter create mobile --org com.wholesales --project-name wholesales_mobile

cd mobile
```

### 1.2 Struktur Monorepo Akhir

```
wholesales-app/
├── backend/          ← Go gRPC (sudah ada)
├── frontend/         ← (nanti web)
└── mobile/           ← Flutter (yang akan kita buat)
    ├── lib/
    ├── android/
    ├── ios/
    └── pubspec.yaml
```

---

## TAHAP 2 — Dependencies (pubspec.yaml)

```yaml
name: wholesales_mobile
description: Wholesales App Mobile

environment:
  sdk: '>=3.0.0 <4.0.0'

  dependencies:
    flutter:
        sdk: flutter

          # HTTP Client
            dio: ^5.4.0

              # State Management
                flutter_bloc: ^8.1.4
                  equatable: ^2.0.5

                    # Navigation
                      go_router: ^13.2.0

                        # Storage (token JWT)
                          flutter_secure_storage: ^9.0.0

                            # UI
                              flutter_svg: ^2.0.9
                                shimmer: ^3.0.0
                                  intl: ^0.19.0             # format currency & date

                                    # Dependency Injection
                                      get_it: ^7.6.7

                                        # Form Validation
                                          formz: ^0.7.0

                                            # Environment Config
                                              flutter_dotenv: ^5.1.0

                                              dev_dependencies:
                                                flutter_test:
                                                    sdk: flutter
                                                      flutter_lints: ^3.0.0
                                                        build_runner: ^2.4.8
```

Jalankan:
```bash
flutter pub get
```

---

## TAHAP 3 — Struktur Folder

```
lib/
├── main.dart
├── app.dart                        ← Root widget + router
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── api_endpoints.dart      ← Base URL & semua endpoint
│   ├── errors/
│   │   └── failures.dart
│   ├── network/
│   │   └── dio_client.dart         ← Dio setup + interceptor JWT
│   ├── router/
│   │   └── app_router.dart         ← GoRouter config
│   ├── storage/
│   │   └── secure_storage.dart     ← Simpan/ambil token
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       ├── currency_formatter.dart
│       └── date_formatter.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── login_request_model.dart
│   │   │   │   ├── register_request_model.dart
│   │   │   │   └── auth_response_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       └── register_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       └── pages/
│   │           ├── login_page.dart
│   │           ├── register_page.dart
│   │           └── splash_page.dart
│   │
│   ├── company/                    ← Fitur khusus Company role
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── company_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── balance_model.dart
│   │   │   │   └── company_profile_model.dart
│   │   │   └── repositories/
│   │   │       └── company_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── company_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── company_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_balance_usecase.dart
│   │   │       └── topup_giro_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── company_bloc.dart
│   │       └── pages/
│   │           ├── company_dashboard_page.dart
│   │           └── topup_giro_page.dart
│   │
│   ├── transfer/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── transfer_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── transfer_request_model.dart
│   │   │   │   └── transfer_history_model.dart
│   │   │   └── repositories/
│   │   │       └── transfer_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── transfer_entity.dart
│   │   │   │   └── transfer_history_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── transfer_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_transfer_usecase.dart
│   │   │       └── get_transfer_history_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── transfer_bloc.dart
│   │       │   └── transfer_history_bloc.dart
│   │       └── pages/
│   │           ├── transfer_page.dart
│   │           ├── transfer_confirm_page.dart
│   │           ├── transfer_success_page.dart
│   │           └── transfer_history_page.dart
│   │
│   └── admin/                      ← Fitur khusus Admin Bank role
│       ├── data/
│       │   ├── datasources/
│       │   │   └── admin_remote_datasource.dart
│       │   ├── models/
│       │   │   ├── employee_model.dart
│       │   │   └── registered_company_model.dart
│       │   └── repositories/
│       │       └── admin_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── employee_entity.dart
│       │   │   └── registered_company_entity.dart
│       │   ├── repositories/
│       │   │   └── admin_repository.dart
│       │   └── usecases/
│       │       ├── get_employees_usecase.dart
│       │       └── get_registered_companies_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   └── admin_bloc.dart
│           └── pages/
│               ├── admin_dashboard_page.dart
│               ├── employee_list_page.dart
│               └── company_list_page.dart
│
└── shared/
    └── widgets/
        ├── custom_button.dart
        ├── custom_text_field.dart
        ├── loading_overlay.dart
        ├── error_snackbar.dart
        └── empty_state_widget.dart
```

---

## TAHAP 4 — Daftar Halaman Lengkap

### 4.1 Halaman Bersama (Auth)

| # | Halaman | Route | Deskripsi |
|---|---------|-------|-----------|
| 1 | **SplashPage** | `/` | Cek token di secure storage, redirect ke login atau dashboard sesuai role |
| 2 | **LoginPage** | `/login` | Form login (email + password). Hit endpoint `POST /api/auth/login` |
| 3 | **RegisterPage** | `/register` | Form registrasi perusahaan (nama, email, password, dll). Hit `POST /api/auth/register` |

### 4.2 Halaman Company Role

| # | Halaman | Route | Deskripsi |
|---|---------|-------|-----------|
| 4 | **CompanyDashboardPage** | `/company/dashboard` | Tampilkan saldo, shortcut transfer, riwayat terbaru |
| 5 | **TransferPage** | `/company/transfer` | Pilih jenis transfer: BI FAST / RTGS / Internal / External |
| 6 | **TransferConfirmPage** | `/company/transfer/confirm` | Tampilkan ringkasan sebelum submit |
| 7 | **TransferSuccessPage** | `/company/transfer/success` | Bukti transfer sukses |
| 8 | **TransferHistoryPage** | `/company/transfer/history` | List riwayat transfer dengan filter & pagination |
| 9 | **TopupGiroPage** | `/company/topup` | Form top-up saldo giro |

### 4.3 Halaman Admin Bank Role

| # | Halaman | Route | Deskripsi |
|---|---------|-------|-----------|
| 10 | **AdminDashboardPage** | `/admin/dashboard` | Ringkasan statistik perusahaan & karyawan |
| 11 | **EmployeeListPage** | `/admin/employees` | Daftar semua karyawan dengan search |
| 12 | **CompanyListPage** | `/admin/companies` | Daftar semua perusahaan yang terdaftar |

**Total: 12 halaman**

---

## TAHAP 5 — Setup Core Layer

### 5.1 API Endpoints (`core/constants/api_endpoints.dart`)

```dart
class ApiEndpoints {
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android emulator
  // static const String baseUrl = 'http://localhost:8080'; // iOS simulator

  // Auth
  static const String login    = '/api/auth/login';
  static const String register = '/api/auth/register';

  // Company
  static const String balance  = '/api/company/balance';
  static const String topup    = '/api/company/topup';

  // Transfer
  static const String transfer        = '/api/transfer';
  static const String transferHistory = '/api/transfer/history';

  // Admin
  static const String employees  = '/api/admin/employees';
  static const String companies  = '/api/admin/companies';
}
```

### 5.2 Dio Client dengan JWT Interceptor (`core/network/dio_client.dart`)

```dart
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../constants/api_endpoints.dart';

class DioClient {
  late final Dio _dio;

  DioClient(SecureStorage secureStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Interceptor: otomatis sisipkan JWT di setiap request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await secureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // 401 = token expired → redirect ke login
        if (error.response?.statusCode == 401) {
          secureStorage.deleteToken();
          // TODO: navigate to login
        }
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
}
```

### 5.3 Secure Storage (`core/storage/secure_storage.dart`)

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _keyToken = 'jwt_token';
  static const _keyRole  = 'user_role';

  Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  Future<String?> getToken() =>
      _storage.read(key: _keyToken);

  Future<void> deleteToken() =>
      _storage.delete(key: _keyToken);

  Future<void> saveRole(String role) =>
      _storage.write(key: _keyRole, value: role);

  Future<String?> getRole() =>
      _storage.read(key: _keyRole);
}
```

---

## TAHAP 6 — Router (GoRouter)

```dart
// core/router/app_router.dart
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: _redirectLogic,
    routes: [
      GoRoute(path: '/',        builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login',   builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register',builder: (_, __) => const RegisterPage()),

      // Company routes
      ShellRoute(
        builder: (_, __, child) => CompanyShell(child: child),
        routes: [
          GoRoute(path: '/company/dashboard', builder: (_, __) => const CompanyDashboardPage()),
          GoRoute(path: '/company/transfer',  builder: (_, __) => const TransferPage()),
          GoRoute(path: '/company/transfer/confirm', builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>;
            return TransferConfirmPage(data: extra);
          }),
          GoRoute(path: '/company/transfer/success', builder: (_, __) => const TransferSuccessPage()),
          GoRoute(path: '/company/transfer/history', builder: (_, __) => const TransferHistoryPage()),
          GoRoute(path: '/company/topup', builder: (_, __) => const TopupGiroPage()),
        ],
      ),

      // Admin routes
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin/dashboard',  builder: (_, __) => const AdminDashboardPage()),
          GoRoute(path: '/admin/employees',  builder: (_, __) => const EmployeeListPage()),
          GoRoute(path: '/admin/companies',  builder: (_, __) => const CompanyListPage()),
        ],
      ),
    ],
  );

  // Redirect logic berdasarkan token & role
  static Future<String?> _redirectLogic(_, GoRouterState state) async {
    final storage = getIt<SecureStorage>();
    final token = await storage.getToken();
    final role  = await storage.getRole();

    final isLoginRoute = state.matchedLocation == '/login';
    final isSplash    = state.matchedLocation == '/';

    if (token == null && !isLoginRoute) return '/login';

    if (isSplash && token != null) {
      return role == 'admin' ? '/admin/dashboard' : '/company/dashboard';
    }

    return null;
  }
}
```

---

## TAHAP 7 — Urutan Pengerjaan Halaman

Ikuti urutan ini supaya tidak bingung saat develop:

```
SPRINT 1 — Foundation
├── [1] Setup project & dependencies
├── [2] Buat core layer (DioClient, SecureStorage, Router)
├── [3] Dependency injection (GetIt)
└── [4] Shared widgets (button, textfield, loading)

SPRINT 2 — Auth Flow
├── [5] SplashPage (cek token & redirect)
├── [6] LoginPage + AuthBloc
└── [7] RegisterPage

SPRINT 3 — Company Core
├── [8] CompanyDashboardPage (tampil saldo)
├── [9] TransferPage (pilih jenis transfer)
├── [10] TransferConfirmPage
└── [11] TransferSuccessPage

SPRINT 4 — Company Lanjutan
├── [12] TransferHistoryPage (list + filter)
└── [13] TopupGiroPage

SPRINT 5 — Admin
├── [14] AdminDashboardPage
├── [15] EmployeeListPage
└── [16] CompanyListPage
```

---

## TAHAP 8 — Contoh Implementasi Auth Feature

### AuthBloc (`features/auth/presentation/bloc/auth_bloc.dart`)

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class AuthEvent {}
class LoginSubmitted extends AuthEvent {
  final String email, password;
  LoginSubmitted({required this.email, required this.password});
}
class RegisterSubmitted extends AuthEvent {
  final String companyName, email, password;
  RegisterSubmitted({required this.companyName, required this.email, required this.password});
}

// States
abstract class AuthState {}
class AuthInitial   extends AuthState {}
class AuthLoading   extends AuthState {}
class AuthSuccess   extends AuthState { final String role; AuthSuccess(this.role); }
class AuthFailure   extends AuthState { final String message; AuthFailure(this.message); }

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUsecase   loginUsecase;
  final RegisterUsecase registerUsecase;

  AuthBloc({required this.loginUsecase, required this.registerUsecase})
      : super(AuthInitial()) {

    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      final result = await loginUsecase(LoginParams(
        email: event.email,
        password: event.password,
      ));
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (user)    => emit(AuthSuccess(user.role)),
      );
    });

    on<RegisterSubmitted>((event, emit) async {
      emit(AuthLoading());
      final result = await registerUsecase(RegisterParams(
        companyName: event.companyName,
        email: event.email,
        password: event.password,
      ));
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_)       => emit(AuthSuccess('company')),
      );
    });
  }
}
```

---

## TAHAP 9 — Tips Penting

### Jalankan di emulator Android (konek ke localhost backend)
```
base URL = http://10.0.2.2:8080
```

### Jalankan di simulator iOS
```
base URL = http://localhost:8080
```

### Izin Internet di Android
Tambahkan di `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Untuk development (cleartext HTTP), tambahkan di `<application>`:
```xml
android:usesCleartextTraffic="true"
```

### Format Currency Rupiah
```dart
import 'package:intl/intl.dart';

final formatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

formatter.format(1500000); // → "Rp 1.500.000"
```

---

## Ringkasan Total File yang Perlu Dibuat

| Layer | Jumlah File |
|-------|------------|
| Core  | ~10 file |
| Feature: auth | ~12 file |
| Feature: company | ~10 file |
| Feature: transfer | ~14 file |
| Feature: admin | ~12 file |
| Shared widgets | ~5 file |
| **Total** | **~63 file** |
