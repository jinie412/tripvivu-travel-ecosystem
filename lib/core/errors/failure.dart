import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
/// Use-cases throw [Failure] subclasses; Cubits catch and emit error states.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Server returned a non-2xx response.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Lỗi từ máy chủ. Vui lòng thử lại.']);
}

/// Device has no internet connection.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Không có kết nối mạng.']);
}

/// Local cache read/write error.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Lỗi bộ nhớ đệm.']);
}

/// Authentication-specific failure (wrong credentials, expired token, etc.).
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Xác thực thất bại.']);
}

/// Unexpected / unclassified error.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Đã xảy ra lỗi không xác định.']);
}