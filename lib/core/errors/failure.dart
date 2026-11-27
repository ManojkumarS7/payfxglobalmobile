abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please check your network.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load cached data.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.statusCode});
}
