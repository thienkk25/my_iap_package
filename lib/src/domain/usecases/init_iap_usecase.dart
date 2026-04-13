import '../../core/usecases/usecase.dart';
import '../entities/iap_product_config.dart';
import '../repositories/iap_repository.dart';

/// UseCase khởi tạo mô-đun theo danh sách sản phẩm cấu hình, cần được gọi trước tiên.
class InitIapUseCase implements UseCase<void, List<IapProductConfig>> {
  final IapRepository repository;

  InitIapUseCase(this.repository);

  @override
  Future<void> call(List<IapProductConfig> params) async {
    return await repository.init(config: params);
  }
}
