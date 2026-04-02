import '../../core/usecases/usecase.dart';
import '../entities/iap_product.dart';
import '../repositories/iap_repository.dart';

class BuyProductUseCase implements UseCase<void, IapProduct> {
  final IapRepository repository;

  BuyProductUseCase(this.repository);

  @override
  Future<void> call(IapProduct params) async {
    return await repository.buy(params);
  }
}
