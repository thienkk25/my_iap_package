import '../../core/usecases/usecase.dart';
import '../entities/user_entitlement.dart';
import '../repositories/iap_repository.dart';

/// UseCase lắng nghe thay đổi trạng thái quyền lợi (entitlement) của người dùng.
class ListenEntitlementsUseCase implements StreamUseCase<UserEntitlement, NoParams> {
  final IapRepository repository;

  ListenEntitlementsUseCase(this.repository);

  @override
  Stream<UserEntitlement> call(NoParams params) {
    return repository.entitlementStream;
  }
}
