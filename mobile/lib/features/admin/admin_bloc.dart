import 'package:flutter_bloc/flutter_bloc.dart';
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
}
