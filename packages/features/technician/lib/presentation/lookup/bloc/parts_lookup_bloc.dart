import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'parts_lookup_event.dart';
import 'parts_lookup_state.dart';
import '../../../domain/usecases/get_inventory_parts_usecase.dart';

class PartsLookupBloc extends Bloc<PartsLookupEvent, PartsLookupState> {
  final GetInventoryPartsUseCase getInventoryPartsUseCase;

  PartsLookupBloc({required this.getInventoryPartsUseCase})
      : super(const PartsLookupInitial()) {
    on<LoadParts>(_onLoadParts);
    on<SearchParts>(_onSearchParts);
  }

  Future<void> _onLoadParts(
    LoadParts event,
    Emitter<PartsLookupState> emit,
  ) async {
    emit(const PartsLookupLoading());

    final result = await getInventoryPartsUseCase(
      GetInventoryPartsParams(query: event.query),
    );

    result.fold(
      (failure) {
        emit(PartsLookupError(
            message: _mapFailureToMessage(failure)));
      },
      (parts) {
        emit(PartsLookupLoaded(parts: parts, query: event.query));
      },
    );
  }

  Future<void> _onSearchParts(
    SearchParts event,
    Emitter<PartsLookupState> emit,
  ) async {
    emit(const PartsLookupLoading());

    final result = await getInventoryPartsUseCase(
      GetInventoryPartsParams(
          query: event.query.isEmpty ? null : event.query),
    );

    result.fold(
      (failure) {
        emit(PartsLookupError(
            message: _mapFailureToMessage(failure)));
      },
      (parts) {
        emit(PartsLookupLoaded(
            parts: parts, query: event.query));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Không thể kết nối server. Vui lòng thử lại.';
    }
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }
}
