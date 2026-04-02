import '../../core/usecases/usecase.dart';
import '../repositories/iap_repository.dart';

class RestorePurchasesUseCase implements UseCase<void, NoParams> {
  final IapRepository repository;

  RestorePurchasesUseCase(this.repository);

  @override
  Future<void> call(NoParams params) async {
    return await repository.restore();
  }
}
