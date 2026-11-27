class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Network connectivity error']);

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Cache error']);

  @override
  String toString() => 'CacheException: $message';
}
