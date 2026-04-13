import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/promotional_offer_signature.dart';

/// Abstract class định nghĩa các phương thức lấy dữ liệu từ `in_app_purchase` local/remote.
abstract class IapRemoteDataSource {
  /// Kiểm tra xem Store có đang hiển thị và hoạt động trên thiết bị này hay không.
  Future<bool> isAvailable();

  /// Truy vấn thông tin các sản phẩm theo danh sách [identifiers].
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);

  /// Khởi tạo một giao dịch mua sản phẩm thông thường.
  Future<bool> buyProduct(ProductDetails productDetails);

  /// Khởi tạo một giao dịch mua sản phẩm với mã khuyến mãi (chỉ hỗ trợ trên thiết bị Apple).
  Future<bool> buyPromotionalOffer(ProductDetails productDetails, String offerIdentifier, PromotionalOfferSignature signature, {String? applicationUserName});

  /// Yêu cầu khôi phục các giao dịch đã mua trong quá khứ.
  Future<void> restorePurchases();

  /// Yêu cầu hiển thị trang nhập mã khuyến mãi (App Store Offer Sheet).
  Future<void> presentCodeRedemptionSheet();

  /// Đánh dấu đã hoàn thành xử lý cho một giao dịch với Store (bắt buộc gọi vào cuối luồng xử lý).
  Future<void> completePurchase(PurchaseDetails purchaseDetails);

  /// Stream trả về danh sách các thay đổi trạng thái mua hàng (Pending, Success, Error).
  Stream<List<PurchaseDetails>> get purchaseStream;
}

/// Implement của `IapRemoteDataSource` sử dụng thư viện `in_app_purchase` của Flutter.
class IapRemoteDataSourceImpl implements IapRemoteDataSource {
  final InAppPurchase _inAppPurchase;

  IapRemoteDataSourceImpl({InAppPurchase? inAppPurchase})
      : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _inAppPurchase.isAvailable();
    } catch (e) {
      throw IapException('Failed to check IAP availability: $e');
    }
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async {
    try {
      return await _inAppPurchase.queryProductDetails(identifiers);
    } catch (e) {
      throw IapException('Failed to query products: $e');
    }
  }

  @override
  Future<bool> buyProduct(ProductDetails productDetails) async {
    try {
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      // Mặc định gọi buyNonConsumable vì gói lifetime/subscription thường không tiêu hao.
      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      throw IapException('Failed to buy product: $e');
    }
  }

  @override
  Future<bool> buyPromotionalOffer(ProductDetails productDetails, String offerIdentifier, PromotionalOfferSignature signature, {String? applicationUserName}) async {
    try {
      if (!Platform.isIOS && !Platform.isMacOS) {
        throw IapException('Promotional offers are only supported on Apple platforms.');
      }

      final paymentDiscount = SKPaymentDiscountWrapper(
        keyIdentifier: signature.keyIdentifier,
        nonce: signature.nonce,
        signature: signature.signature,
        timestamp: signature.timestamp,
        identifier: offerIdentifier,
      );

      final purchaseParam = AppStorePurchaseParam(
        productDetails: productDetails,
        applicationUserName: applicationUserName,
        discount: paymentDiscount,
      );

      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      throw IapException('Failed to buy promotional offer: $e');
    }
  }

  @override
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      throw IapException('Failed to restore purchases: $e');
    }
  }

  @override
  Future<void> presentCodeRedemptionSheet() async {
    try {
      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.presentCodeRedemptionSheet();
      } else {
        throw IapException('Offer codes redemption is only supported on iOS platforms.');
      }
    } catch (e) {
      throw IapException('Failed to present code redemption sheet: $e');
    }
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    try {
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    } catch (e) {
      throw IapException('Failed to complete purchase: $e');
    }
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _inAppPurchase.purchaseStream;
}
