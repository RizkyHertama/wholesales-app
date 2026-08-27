import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_repository.dart';

// ── Events ──
abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email, password;
  LoginRequested(this.email, this.password);
}

class RegisterRequested extends AuthEvent {
  final String name, email, password;
  RegisterRequested(this.name, this.email, this.password);
}

class LogoutRequested extends AuthEvent {}

// ── States ──
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

class AuthLoggedOut extends AuthState {}

// ── Bloc ──
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    on<LoginRequested>((e, emit) async {
      emit(AuthLoading());
      try {
        await _repo.login(e.email, e.password);
        emit(AuthSuccess());
      } catch (err) {
        emit(AuthFailure(_parseError(err)));
      }
    });

    on<RegisterRequested>((e, emit) async {
      emit(AuthLoading());
      try {
        await _repo.register(e.name, e.email, e.password);
        emit(AuthSuccess());
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
    if (err is String) {
      return err; // Jika repository melempar throw 'Pesan error'
    } else if (err is Exception) {
      // Menghapus tulisan 'Exception: ' atau 'DioException [bad response]: '
      return err.toString().replaceAll(RegExp(r'^.*Exception:?\s*'), '');
    }
    return err
        .toString(); // Menampilkan pesan error aslinya, bukan string 'hehe' lagi
  }
}
