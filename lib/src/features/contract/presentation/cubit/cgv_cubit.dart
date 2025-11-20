import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/use_cases/get_cgv_per_offer_use_case.dart';

part 'cgv_state.dart';

class CgvCubit extends Cubit<CgvState> {
  final GetCgvPerOfferUseCase getCgvPerOfferUseCase;
  CgvCubit({required this.getCgvPerOfferUseCase}) : super(CgvInitial());

  Future<Uint8List> getCGV({required String offerName, required String lang}) async {
    final failureOrBytes = await getCgvPerOfferUseCase(offerName: offerName, lang: lang);

    return failureOrBytes.fold(
      (error) {
        emit(LoadCGVFailed());
        return Uint8List(0);
      },
      (pdfBytes) => pdfBytes,
    );
  }
}
