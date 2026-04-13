import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/promotional_offer_signature.dart';

/// Abstract class định nghĩa các phương thức lấy dữ liệu từ `in_app_purchase` local/remote.
abstract class IapRemoteDataSource {
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<bool> buyProduct(ProductDetails productDetails);
  Future<bool> buyPromotionalOffer(ProductDetails productDetails, String offerIdentifier, PromotionalOfferSignature signature, {String? applicationUserName});
  Future<void> restorePurchases();
  Future<void> presentCodeRedemptionSheet();
  Future<void> completePurchase(PurchaseDetails purchaseDetails);
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
