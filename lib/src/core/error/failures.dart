abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});
}

class IapFailure extends Failure {
  const IapFailure(super.message, {super.code});

  @override
  String toString() {
    if (code != null) return 'IapFailure: [$code] $message';
    return 'IapFailure: $message';
  }
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
  
  @override
  String toString() => 'NetworkFailure: $message';
}
