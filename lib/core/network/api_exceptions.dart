class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException([super.message = 'No internet connection. Please check your network and try again.']);
}

class TimeoutException extends ApiException {
  TimeoutException([super.message = 'Connection timed out. Please try again later.']);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Session expired. Please login again.']);
}

class NotFoundException extends ApiException {
  NotFoundException([super.message = 'Requested resource not found.']);
}

class ServerException extends ApiException {
  ServerException([super.message = 'Server encountered an error. Please try again later.']);
}

