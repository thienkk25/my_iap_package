/// Lớp cơ sở (Base class) đại diện cho các lỗi nghiệp vụ trong hệ thống.
abstract class Failure {
  /// Thông báo lỗi chi tiết.
  final String message;
  
  /// Mã lỗi (tuỳ chọn) để định danh lỗi cụ thể.
  final String? code;

  const Failure(this.message, {this.code});
}

/// Lỗi liên quan đến In-App Purchase (chưa thể mua, lỗi giao dịch, v.v.).
class IapFailure extends Failure {
  const IapFailure(super.message, {super.code});

  @override
  String toString() {
    if (code != null) return 'IapFailure: [$code] $message';
    return 'IapFailure: $message';
  }
}

/// Lỗi liên quan đến kết nối mạng (dành cho các thao tác cần Validate với Server backend).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
  
  @override
  String toString() => 'NetworkFailure: $message';
}
