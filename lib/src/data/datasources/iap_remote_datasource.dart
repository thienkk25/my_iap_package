import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/error/exceptions.dart';

/// Abstract class định nghĩa các phương thức lấy dữ liệu từ `in_app_purchase` local/remote.
abstract class IapRemoteDataSource {
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<bool> buyProduct(ProductDetails productDetails);
  Future<void> restorePurchases();
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
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      throw IapException('Failed to restore purchases: $e');
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
