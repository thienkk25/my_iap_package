import '../entities/iap_product.dart';
import '../entities/iap_product_config.dart';
import '../entities/user_entitlement.dart';

/// Giao diện (Interface) định nghĩa các thao tác mua hàng.
/// Lớp Domain chỉ thao tác với interface này để đảm bảo Clean Architecture.
abstract class IapRepository {
  /// Khởi tạo module bằng danh sách cấu hình các sản phẩm.
  Future<void> init({required List<IapProductConfig> config});

  /// Tải thông tin chi tiết (giá, tên, mô tả) của các sản phẩm được cấu hình ở `init`.
  Future<List<IapProduct>> getProducts();

  /// Thực hiện mua một sản phẩm.
  Future<void> buy(IapProduct product);

  /// Khôi phục (restore) lại các đơn hàng đã mua trong quá khứ. (Apple bắt buộc phải có tính năng này).
  Future<void> restore();

  /// Stream trả về trạng thái quyền lợi mới nhất của người dùng cục bộ.
  Stream<UserEntitlement> get entitlementStream;
}
