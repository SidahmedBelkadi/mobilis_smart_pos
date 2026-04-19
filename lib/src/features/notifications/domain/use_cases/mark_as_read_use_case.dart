import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/notification_repository.dart';

class MarkAsReadUseCase {
  final NotificationRepository repository;

  MarkAsReadUseCase({required this.repository});

  Future<Either<Failure, void>> call(int id) async {
    return await repository.markAsRead(id);
  }
}
