import 'package:flutter_bloc/flutter_bloc.dart';
import 'company_repository.dart';

// ── Events ──────────────────────────────────────────
abstract class CompanyEvent {}

class LoadBalance extends CompanyEvent {}

// ── States ──────────────────────────────────────────
abstract class CompanyState {}

class CompanyInitial extends CompanyState {}

class CompanyLoading extends CompanyState {}

class BalanceLoaded extends CompanyState {
  final double balance;
  BalanceLoaded(this.balance);
}

class CompanyError extends CompanyState {
  final String message;
  CompanyError(this.message);
}

// ── Bloc ────────────────────────────────────────────
class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  final CompanyRepository _repo;

  CompanyBloc(this._repo) : super(CompanyInitial()) {
    on<LoadBalance>((e, emit) async {
      emit(CompanyLoading());
      try {
        final balance = await _repo.getBalance();
        emit(BalanceLoaded(balance));
      } catch (err) {
        emit(CompanyError(err.toString().replaceAll('Exception: ', '')));
      }
    });
  }
}
