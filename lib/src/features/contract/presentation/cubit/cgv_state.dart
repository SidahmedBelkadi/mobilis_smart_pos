part of 'cgv_cubit.dart';

sealed class CgvState extends Equatable {
  const CgvState();

  @override
  List<Object> get props => [];
}

final class CgvInitial extends CgvState {}

final class LoadCGVFailed extends CgvState {}

final class LoadCGVSucceded extends CgvState {}

final class LoadCGVLoading extends CgvState {}
