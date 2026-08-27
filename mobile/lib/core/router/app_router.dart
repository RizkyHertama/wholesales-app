import 'package:go_router/go_router.dart';
import '../../features/auth/splash_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/company/company_dashboard_page.dart';
import '../../features/company/topup_giro_page.dart';
import '../../features/transfer/transfer_page.dart';
import '../../features/transfer/transfer_confirm_page.dart';
import '../../features/transfer/transfer_success_page.dart';
import '../../features/transfer/transfer_history_page.dart';
import '../storage/secure_storage.dart';

class AppRouter {
  static GoRouter router(SecureStorage storage) => GoRouter(
        initialLocation: '/',
        redirect: (context, state) async {
          final token = await storage.getToken();
          final loc = state.matchedLocation;

          // 1. Jika belum login dan mencoba masuk ke halaman internal -> lempar ke /login
          if (token == null && loc != '/login' && loc != '/register') {
            return '/login';
          }

          // 2. Jika sudah login tapi buka halaman auth / splash -> lempar ke dashboard company
          if (token != null &&
              (loc == '/login' || loc == '/register' || loc == '/')) {
            return '/company/dashboard';
          }

          return null;
        },
        routes: [
          GoRoute(path: '/', builder: (_, __) => const SplashPage()),
          GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
          GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
          GoRoute(
              path: '/company/dashboard',
              builder: (_, __) => const CompanyDashboardPage()),
          GoRoute(
              path: '/company/topup',
              builder: (_, __) => const TopupGiroPage()),
          GoRoute(
              path: '/company/transfer',
              builder: (_, __) => const TransferPage()),
          GoRoute(
              path: '/company/transfer/confirm',
              builder: (_, s) => TransferConfirmPage(
                  data: s.extra as Map<String, dynamic>? ?? {})),
          GoRoute(
              path: '/company/transfer/success',
              builder: (_, __) => const TransferSuccessPage()),
          GoRoute(
              path: '/company/transfer/history',
              builder: (_, __) => const TransferHistoryPage()),
        ],
      );
}
