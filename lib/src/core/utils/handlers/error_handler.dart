
import '../../error/exception.dart';
import '../ressources/app_api_messages.dart';

class ErrorHandler {
  static String getErrorMessage(ServerException exception) {
    if (exception is FetchDataException) {
      return exception.message ?? AppApiResponsesMessages.errorDuringCommunication;
    } else if (exception is BadRequestException) {
      return exception.message ?? AppApiResponsesMessages.badRequest;
    } else if (exception is UnauthorizedException) {
      return exception.message ?? AppApiResponsesMessages.unauthorized;
    } else if (exception is NotFoundException) {
      return exception.message ?? AppApiResponsesMessages.requestedInfoNotFound;
    } else if (exception is ConflictException) {
      return exception.message ?? AppApiResponsesMessages.conflictOccurred;
    } else if (exception is InternalServerErrorException) {
      return exception.message ?? AppApiResponsesMessages.internalServerError;
    } else if (exception is ServiceUnavailableException) {
      return exception.message ?? 'app_under_maintenance';
    } else if (exception is NoInternetConnectionException) {
      return exception.message ?? AppApiResponsesMessages.noInternetConnection;
    } else if (exception is CancelRequestException) {
      return exception.message ?? AppApiResponsesMessages.noInternetConnection;
    } else if (exception is UnprocessableEntityException) {
      return exception.message ?? AppApiResponsesMessages.unprocessable;
    } else {
      return AppApiResponsesMessages.unexpectedError;
    }
  }
}
