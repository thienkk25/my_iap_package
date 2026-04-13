/// Abstract/base Exception dùng cho các ngoại lệ xảy ra chủ yếu ở lớp Data.
class IapException implements Exception {
  /// Thông báo chi tiết của ngoại lệ.
  final String message;
  
  /// Mã định danh ngoại lệ (nếu có).
  final String? code;

  IapException(this.message, {this.code});

  @override
  String toString() {
    if (code != null) return 'IapException: [$code] $message';
    return 'IapException: $message';
  }
}
