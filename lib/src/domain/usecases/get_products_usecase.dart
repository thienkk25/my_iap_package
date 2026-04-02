import '../../core/usecases/usecase.dart';
import '../entities/iap_product.dart';
import '../repositories/iap_repository.dart';

class GetProductsUseCase implements UseCase<List<IapProduct>, NoParams> {
  final IapRepository repository;

  GetProductsUseCase(this.repository);

  @override
  Future<List<IapProduct>> call(NoParams params) async {
    return await repository.getProducts();
  }
}
