import '../../core/usecases/usecase.dart';
import '../entities/iap_product.dart';
import '../entities/promotional_offer_signature.dart';
import '../repositories/iap_repository.dart';

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
