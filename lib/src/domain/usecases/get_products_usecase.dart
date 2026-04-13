import '../../core/usecases/usecase.dart';
import '../entities/iap_product.dart';
import '../repositories/iap_repository.dart';

/// UseCase dùng để truy vấn, lấy danh sách các sản phẩm (products) từ kho ứng dụng (App Store/Google Play).
class GetProductsUseCase implements UseCase<List<IapProduct>, NoParams> {
  final IapRepository repository;

  GetProductsUseCase(this.repository);

  @override
  Future<List<IapProduct>> call(NoParams params) async {
    return await repository.getProducts();
  }
}
