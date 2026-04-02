class IapException implements Exception {
  final String message;
  final String? code;

  IapException(this.message, {this.code});

  @override
  String toString() {
    if (code != null) return 'IapException: [$code] $message';
    return 'IapException: $message';
  }
}
