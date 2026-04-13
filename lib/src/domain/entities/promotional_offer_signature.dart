/// Lớp đại diện cho chữ ký bảo mật (signature) dùng để xác thực một ưu đãi (Promotional Offer) với Apple.
/// Chữ ký này phải được gen từ Backend tuân thủ theo chuẩn Apple StoreKit.
class PromotionalOfferSignature {
  /// Chuỗi định danh của khoá (Key ID) được cấp trong App Store Connect.
  final String keyIdentifier;

  /// Chuỗi ngẫu nhiên (UUID) tạo cho giao dịch này (nonce) để chống Replay Attack.
  final String nonce;

  /// Chuỗi chữ ký mã hoá theo thuật toán ECDSA với khoá riêng tư (Private Key P-256).
  final String signature;

  /// Thời gian tạo chữ ký dưới dạng Unix Timestamp (milliseconds/seconds).
  final int timestamp;

  PromotionalOfferSignature({
    required this.keyIdentifier,
    required this.nonce,
    required this.signature,
    required this.timestamp,
  });

  factory PromotionalOfferSignature.fromJson(Map<String, dynamic> json) {
    return PromotionalOfferSignature(
      keyIdentifier: json['keyIdentifier'] as String,
      nonce: json['nonce'] as String,
      signature: json['signature'] as String,
      timestamp: json['timestamp'] as int,
    );
  }
}
