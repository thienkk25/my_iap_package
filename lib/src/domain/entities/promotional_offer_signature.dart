class PromotionalOfferSignature {
  final String keyIdentifier;
  final String nonce;
  final String signature;
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
