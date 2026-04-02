import '../entities/user_entitlement.dart';

/// Interface cho phép ứng dụng bên ngoài cắm (inject) backend validator vào package IAP nội bộ.
/// Mặc định nếu không có, package có thể có cơ chế verify bằng mã local.
abstract class ReceiptValidator {
  /// Hàm verify có nhiệm vụ kiểm tra với server và trả về trạng thái [UserEntitlement].
  /// Tham số `purchaseData` chứa mã đối soát giao dịch (tuỳ nền tảng iOS/Android).
  Future<UserEntitlement> verify(dynamic purchaseData);
}
