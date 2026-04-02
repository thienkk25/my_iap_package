import '../../core/usecases/usecase.dart';
import '../../domain/entities/iap_product.dart';
import '../../domain/entities/iap_product_config.dart';
import '../../domain/entities/user_entitlement.dart';

import '../../domain/usecases/init_iap_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/buy_product_usecase.dart';
import '../../domain/usecases/restore_purchases_usecase.dart';
import '../../domain/usecases/listen_entitlements_usecase.dart';

import '../../data/datasources/iap_remote_datasource.dart';
import '../../data/repositories/iap_repository_impl.dart';
import '../../domain/repositories/receipt_validator.dart';

/// Lớp Facade, đóng vai trò như một Manager duy nhất để ứng dụng tương tác.
/// Bản thân nó không duy trì State gì cả (tuân theo nguyên tắc No Bloc, pure Dart).
/// Nó sẽ khởi tạo toàn bộ cấu trúc Clean Architecture bên dưới nội bộ.
class IapManager {
  late final InitIapUseCase _initIapUseCase;
  late final GetProductsUseCase _getProductsUseCase;
  late final BuyProductUseCase _buyProductUseCase;
  late final RestorePurchasesUseCase _restorePurchasesUseCase;
  late final ListenEntitlementsUseCase _listenEntitlementsUseCase;

  /// Tạo một IapManager mới, tuỳ chọn truyền vào ReceiptValidator nếu bạn có backend.
  IapManager({ReceiptValidator? validator}) {
    // Dependency Injection thủ công (Manual DI) để package tự chạy không cần `get_it`.
    final remoteDataSource = IapRemoteDataSourceImpl();
    final repository = IapRepositoryImpl(
      remoteDataSource: remoteDataSource,
      receiptValidator: validator,
    );

    _initIapUseCase = InitIapUseCase(repository);
    _getProductsUseCase = GetProductsUseCase(repository);
    _buyProductUseCase = BuyProductUseCase(repository);
    _restorePurchasesUseCase = RestorePurchasesUseCase(repository);
    _listenEntitlementsUseCase = ListenEntitlementsUseCase(repository);
  }

  /// Khởi tạo IAP với danh sách cấu hình.
  Future<void> init({required List<IapProductConfig> config}) async {
    await _initIapUseCase(config);
  }

  /// Lấy danh sách sản phẩm từ Store.
  Future<List<IapProduct>> getProducts() async {
    return await _getProductsUseCase(NoParams());
  }

  /// Tiến hành mua một sản phẩm.
  Future<void> buy(IapProduct product) async {
    await _buyProductUseCase(product);
  }

  /// Khôi phục các giao dịch trong quá khứ.
  Future<void> restore() async {
    await _restorePurchasesUseCase(NoParams());
  }

  /// Stream trả về trạng thái quyền lợi người dùng (ví dụ: đã đăng ký Pro hay chưa).
  /// App có thể lắng nghe `entitlementStream.listen()` tại bất kỳ file nào.
  Stream<UserEntitlement> get entitlementStream {
    return _listenEntitlementsUseCase(NoParams());
  }
}
