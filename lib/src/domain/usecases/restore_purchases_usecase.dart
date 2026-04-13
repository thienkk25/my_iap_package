import '../../core/usecases/usecase.dart';
import '../repositories/iap_repository.dart';

/// UseCase thực hiện chức năng khôi phục lại các đơn hàng và giao dịch đã mua trong quá khứ của người dùng.
class RestorePurchasesUseCase implements UseCase<void, NoParams> {
  final IapRepository repository;

  RestorePurchasesUseCase(this.repository);

  @override
  Future<void> call(NoParams params) async {
    return await repository.restore();
  }
}
