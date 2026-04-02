import '../../core/usecases/usecase.dart';
import '../entities/iap_product_config.dart';
import '../repositories/iap_repository.dart';

class InitIapUseCase implements UseCase<void, List<IapProductConfig>> {
  final IapRepository repository;

  InitIapUseCase(this.repository);

  @override
  Future<void> call(List<IapProductConfig> params) async {
    return await repository.init(config: params);
  }
}
