import 'package:flutter_bloc/flutter_bloc.dart';
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
}
