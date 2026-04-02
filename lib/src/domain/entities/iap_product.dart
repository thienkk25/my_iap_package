/// Đại diện cho một sản phẩm bày bán trên Store (đã được bọc lại để không phụ thuộc vào thư viện cụ thể).
class IapProduct {
  /// Mã định danh của sản phẩm.
  final String id;

  /// Tiêu đề của sản phẩm đã được bản địa hoá trên Store.
  final String title;

  /// Mô tả sản phẩm đã bản địa hoá.
  final String description;

  /// Giá tiền định dạng chuẩn (ví dụ: "99.000 đ", "$4.99").
  final String price;

  /// Ký hiệu tiền tệ gốc (ví dụ: "VND", "USD").
  final String currencyCode;

  /// Giá trị raw (không bao gồm format tiền tệ).
  final double rawPrice;

  /// Một tham chiếu trỏ ngược về object gốc của system (in_app_purchase's ProductDetails) 
  /// để thuận tiện cho việc xử lý lúc call thực thi hành động buy().
  final dynamic _rawDetails;

  const IapProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.rawPrice,
    required dynamic rawDetails,
  }) : _rawDetails = rawDetails;

  /// Lấy đối tượng raw hệ thống (chỉ dùng nội bộ cho lớp Data/Repository).
  dynamic get rawDetails => _rawDetails;
}
