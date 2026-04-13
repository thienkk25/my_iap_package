import '../../core/usecases/usecase.dart';
import '../entities/iap_product.dart';
import '../entities/promotional_offer_signature.dart';
import '../repositories/iap_repository.dart';

/// Các tham số cần thiết để thực hiện giao dịch mua một sản phẩm kèm ưu đãi đặc biệt (Promotional Offer).
class BuyPromotionalOfferParams {
  final IapProduct product;
  final String offerIdentifier;
  final PromotionalOfferSignature signature;
  final String? applicationUserName;

  BuyPromotionalOfferParams({
    required this.product,
    required this.offerIdentifier,
    required this.signature,
    this.applicationUserName,
  });
}

/// UseCase xử lý việc mua sản phẩm kèm theo ưu đãi đặc biệt (Promotional Offer) cho các tài khoản đủ điều kiện.
class BuyPromotionalOfferUseCase implements UseCase<void, BuyPromotionalOfferParams> {
  final IapRepository repository;

  BuyPromotionalOfferUseCase(this.repository);

  @override
  Future<void> call(BuyPromotionalOfferParams params) async {
    return await repository.buyPromotionalOffer(
      params.product,
      params.offerIdentifier,
      params.signature,
      applicationUserName: params.applicationUserName,
    );
  }
}
