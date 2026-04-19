import '../../core/usecases/usecase.dart';
import '../../domain/entities/iap_product.dart';
import '../../domain/entities/iap_product_config.dart';
import '../../domain/entities/user_entitlement.dart';
import '../../domain/entities/promotional_offer_signature.dart';

import '../../domain/usecases/init_iap_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/buy_product_usecase.dart';
import '../../domain/usecases/buy_promotional_offer_usecase.dart';
import '../../domain/usecases/restore_purchases_usecase.dart';
import '../../domain/usecases/listen_entitlements_usecase.dart';
import '../../domain/usecases/present_code_redemption_sheet_usecase.dart';

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
  late final BuyPromotionalOfferUseCase _buyPromotionalOfferUseCase;
  late final RestorePurchasesUseCase _restorePurchasesUseCase;
  late final ListenEntitlementsUseCase _listenEntitlementsUseCase;
  late final PresentCodeRedemptionSheetUseCase _presentCodeRedemptionSheetUseCase;

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
    _buyPromotionalOfferUseCase = BuyPromotionalOfferUseCase(repository);
    _restorePurchasesUseCase = RestorePurchasesUseCase(repository);
    _listenEntitlementsUseCase = ListenEntitlementsUseCase(repository);
    _presentCodeRedemptionSheetUseCase = PresentCodeRedemptionSheetUseCase(repository);
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
  /// 
  /// **Tích hợp Introductory Offer (Dùng thử miễn phí, Giảm giá nạp đầu):**
  /// Đối với Apple App Store và Google Play, Introductory Offer được áp dụng
  /// THEO CÁCH TỰ ĐỘNG dựa trên tài khoản của người dùng.
  /// Bạn CÓ THỂ hiển thị giá gốc/giá ưu đãi ở UI, nhưng khi gọi hàm `buy` này,
  /// Native OS sẽ kiểm tra xem người dùng đã từng xài thử (trial) chưa.
  /// - Nếu chưa: Store sẽ tự động trừ 0đ (Free trial) hoặc trừ giá ưu đãi, webhook trả về `offerType = 1`.
  /// - Nếu đã xài thử rồi: Store sẽ charge giá gốc bình thường.
  /// => Framework này handle tự động hoàn toàn việc trigger luồng trial/introductory.
  Future<void> buy(IapProduct product) async {
    await _buyProductUseCase(product);
  }

  /// Tiến hành mua sản phẩm với Promotional Offer (Dành riêng cho StoreKit 2 / iOS).
  /// 
  /// **Tích hợp Promotional Offer (Ưu đãi giữ chân người dùng):**
  /// Được dùng khi bạn muốn cấp mã giảm giá hoặc giá rẻ hơn cho NGƯỜI ĐÃ TỪNG MUA (đã huỷ gia hạn).
  /// 
  /// **Cách tích hợp cho dự án khác (iOS):**
  /// 1. App yêu cầu Server của bạn sinh ra 1 chữ ký bảo mật (Signature).
  /// 2. Server gọi hàm `generatePromotionalSignature()` để ký và trả về Client.
  /// 3. Client lấy chữ ký đó gán vào `PromotionalOfferSignature` và truyền vào đây.
  /// 4. Hàm này sẽ truyền Signature trực tiếp xuống Apple StoreKit 2 để mua gói Offer
  ///    thông qua `Sk2PurchaseParam` + `SK2PromotionalOffer`.
  Future<void> buyPromotionalOffer(IapProduct product, String offerIdentifier, PromotionalOfferSignature signature, {String? applicationUserName}) async {
    await _buyPromotionalOfferUseCase(BuyPromotionalOfferParams(
      product: product,
      offerIdentifier: offerIdentifier,
      signature: signature,
      applicationUserName: applicationUserName,
    ));
  }

  /// Khôi phục các giao dịch trong quá khứ.
  Future<void> restore() async {
    await _restorePurchasesUseCase(NoParams());
  }

  /// Mở màn hình nhập Mã Ưu Đãi (Offer Codes) do hệ thống Apple cung cấp.
  /// 
  /// **Tích hợp Offer Codes (Mã nhập ngoài ứng dụng):**
  /// 1. Bạn tạo các mã Text Code hoặc link trên App Store Connect (Ví dụ: "SUMMER99").
  /// 2. Khi bạn gọi hàm này, hệ điều hành iOS (chỉ hỗ trợ iOS 14+) sẽ tự động hiển thị 
  ///    1 bottom sheet pop-up gốc (Native) của App Store để user nhập mã.
  /// 3. Nếu nhập đúng, webhook sẽ trả về `offerType = 3`. 
  /// 4. Stream `entitlementStream` sẽ tự động bắn ra Entitlement mới nếu giao dịch thành công.
  /// 
  /// *Lưu ý: Chỉ hoạt động trên Apple Devices (iOS/macOS).*
  Future<void> presentCodeRedemptionSheet() async {
    await _presentCodeRedemptionSheetUseCase(NoParams());
  }

  /// Stream trả về trạng thái quyền lợi người dùng (ví dụ: đã đăng ký Pro hay chưa).
  /// App có thể lắng nghe `entitlementStream.listen()` tại bất kỳ file nào.
  Stream<UserEntitlement> get entitlementStream {
    return _listenEntitlementsUseCase(NoParams());
  }
}
