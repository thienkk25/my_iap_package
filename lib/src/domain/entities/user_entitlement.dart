/// Đại diện cho trạng thái quyền lợi (sở hữu/đăng ký) hiện tại của người dùng.
/// Ứng dụng sẽ dựa vào đây để mở khoá tính năng (Premium/Pro).
class UserEntitlement {
  /// Bằng true nếu người dùng có quyền lợi hợp lệ (đang kích hoạt lifetime hoặc có subscription còn hạn).
  final bool isActive;

  /// Bằng true nếu quyền lợi này là mua đứt trọn đời (lifetime).
  final bool isLifetime;

  /// Thời điểm hết hạn của gói đăng ký (nếu có).
  /// Sẽ là null nếu user mua lifetime hoặc không có gói nào đang active.
  final DateTime? expiresAt;

  const UserEntitlement({
    required this.isActive,
    required this.isLifetime,
    this.expiresAt,
  });

  /// Factory helper: tạo trạng thái rỗng chưa mua bất cứ thứ gì.
  factory UserEntitlement.inactive() {
    return const UserEntitlement(
      isActive: false,
      isLifetime: false,
      expiresAt: null,
    );
  }
}
