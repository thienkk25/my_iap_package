import 'iap_product_type.dart';

/// Cấu hình cho một sản phẩm In-App Purchase.
/// Giúp package biết cần phải lấy thông tin của những sản phẩm nào từ Store.
class IapProductConfig {
  /// Mã định danh (ID) duy nhất của sản phẩm trên App Store / Google Play.
  final String id;

  /// Loại sản phẩm (mua đứt hay là đăng ký gia hạn).
  final IapProductType type;

  /// Khoảng thời gian có hiệu lực của gói đăng ký (ví dụ: 30 ngày cho gói tháng).
  /// Thuộc tính này tuỳ chọn, dùng để giúp kiểm tra quyền lợi (entitlement) ở local nếu cần.
  final Duration? duration;

  const IapProductConfig({
    required this.id,
    required this.type,
    this.duration,
  });
}
