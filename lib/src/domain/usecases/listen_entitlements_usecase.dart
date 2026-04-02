import '../../core/usecases/usecase.dart';
import '../entities/user_entitlement.dart';
import '../repositories/iap_repository.dart';

class ListenEntitlementsUseCase implements StreamUseCase<UserEntitlement, NoParams> {
  final IapRepository repository;

  ListenEntitlementsUseCase(this.repository);

  @override
  Stream<UserEntitlement> call(NoParams params) {
    return repository.entitlementStream;
  }
}
