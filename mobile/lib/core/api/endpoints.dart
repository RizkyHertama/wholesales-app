class ApiEndpoints {
  // static const String baseUrl = 'http://10.0.2.2:8080'; // Android emulator
  // static const String baseUrl = 'http://localhost:8080'; // Web
  static const String baseUrl = 'http://10.168.82.196:8080';

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';

  // Company
  static const String balance = '/api/company/balance';
  static const String topup = '/api/company/topup';

  // Transfer
  static const String transfer = '/api/transfer';
  static const String transferHistory = '/api/transfer/history';

  // Admin
  static const String employees = '/api/admin/employees';
  static const String companies = '/api/admin/companies';
}
