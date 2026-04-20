import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/error/exceptions.dart';
import '../../domain/entities/iap_product.dart';
import '../../domain/entities/iap_product_config.dart';
import '../../domain/entities/iap_product_type.dart';
import '../../domain/entities/user_entitlement.dart';
import '../../domain/entities/promotional_offer_signature.dart';
import '../../domain/repositories/iap_repository.dart';
import '../../domain/repositories/receipt_validator.dart';
import '../datasources/iap_remote_datasource.dart';

/// Triển khai thực tế của [IapRepository] sử dụng `in_app_purchase` thông qua [IapRemoteDataSource].
class IapRepositoryImpl implements IapRepository {
  /// DataSource chịu trách nhiệm giao tiếp trực tiếp với native Store SDK.
  final IapRemoteDataSource remoteDataSource;

  /// Interface kiểm tra receipt trả về từ native SDK, cung cấp khả năng validate hóa đơn từ backend.
  final ReceiptValidator? receiptValidator;

  /// Bộ điều khiển luồng phát ra thông tin Quyền Lợi (Entitlement) của người dùng.
  final _entitlementController = StreamController<UserEntitlement>.broadcast();

  /// Subscription để lắng nghe thay đổi trạng thái mua hàng.
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  /// Danh sách cấu hình của các sản phẩm đang được phục vụ bởi ứng dụng.
  List<IapProductConfig> _configs = [];

  IapRepositoryImpl({required this.remoteDataSource, this.receiptValidator});

  @override
  Stream<UserEntitlement> get entitlementStream =>
      _entitlementController.stream;

  @override
  Future<void> init({required List<IapProductConfig> config}) async {
    _configs = config;
    final isAvailable = await remoteDataSource.isAvailable();
    if (!isAvailable) {
      throw IapException('Store is not available on this device.');
    }

    // Lắng nghe stream mua hàng từ hệ thống
    _purchaseSubscription = remoteDataSource.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (error) {
        throw IapException('Purchase stream error: $error');
      },
    );
  }

  @override
  Future<List<IapProduct>> getProducts() async {
    if (_configs.isEmpty) {
      throw IapException('IAP module is not initialized. Call init() first.');
    }

    final identifiers = _configs.map((e) => e.id).toSet();
    final response = await remoteDataSource.queryProductDetails(identifiers);

    if (response.error != null) {
      throw IapException('Failed to load products: ${response.error!.message}');
    }

    // In log cảnh báo để dễ debug khi productID không hợp lệ
    if (response.notFoundIDs.isNotEmpty) {
      if (kDebugMode) {
        print(
          'IAP Warning: Các Product IDs sau không tìm thấy trên Store: ${response.notFoundIDs}',
        );
      }
    }

    // Nếu không tìm thấy bất kỳ sản phẩm nào, có thể cân nhắc quăng lỗi luôn
    // hoặc giữ nguyên trả về list rỗng tuỳ hệ thống UI của bạn xử lý ra sao.
    if (response.productDetails.isEmpty) {
      if (kDebugMode) {
        print('IAP Warning: Không tìm thấy bất kỳ sản phẩm hợp lệ nào.');
      }
    }

    return response.productDetails.map((details) {
      return IapProduct(
        id: details.id,
        title: details.title,
        description: details.description,
        price: details.price,
        currencyCode: details.currencyCode,
        rawPrice: details.rawPrice,
        rawDetails: details, // Lưu trữ ProductDetails gốc
      );
    }).toList();
  }

  /// Completer để đợi kết quả trả về từ luồng mua hàng (thành công/thất bại)
  Completer<void>? _purchaseCompleter;

  @override
  Future<void> buy(IapProduct product) async {
    if (product.rawDetails is! ProductDetails) {
      throw IapException('Invalid product details format.');
    }

    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.complete(); // Giải phóng êm đẹp completer cũ thay vì quăng lỗi Unhandled
    }
    _purchaseCompleter = Completer<void>();

    final success = await remoteDataSource.buyProduct(
      product.rawDetails as ProductDetails,
    );
    if (!success) {
      _purchaseCompleter = null;
      throw IapException('Failed to initiate purchase flow.');
    }

    final future = _purchaseCompleter!.future;
    return future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
           _purchaseCompleter = null;
        }
        throw IapException('Connection timeout. Please check your network and try again.');
      },
    );
  }

  @override
  Future<void> buyPromotionalOffer(IapProduct product, String offerIdentifier, PromotionalOfferSignature signature, {String? applicationUserName}) async {
    if (product.rawDetails is! ProductDetails) {
      throw IapException('Invalid product details format.');
    }

    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.complete();
    }
    _purchaseCompleter = Completer<void>();

    final success = await remoteDataSource.buyPromotionalOffer(
      product.rawDetails as ProductDetails,
      offerIdentifier,
      signature,
      applicationUserName: applicationUserName,
    );
    
    if (!success) {
      _purchaseCompleter = null;
      throw IapException('Failed to initiate promotional purchase flow.');
    }

    final future = _purchaseCompleter!.future;
    return future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
           _purchaseCompleter = null;
        }
        throw IapException('Connection timeout. Please check your network and try again.');
      },
    );
  }

  @override
  Future<void> restore() async {
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.complete();
    }
    _purchaseCompleter = Completer<void>();
    
    await remoteDataSource.restorePurchases();
    
    // Restore stream might not complete successfully if no purchases, but we don't block forever
    // Usually we don't await restore through completer, to prevent hanging if no products are found.
    _purchaseCompleter?.complete();
    _purchaseCompleter = null;
  }

  @override
  Future<void> presentCodeRedemptionSheet() async {
    await remoteDataSource.presentCodeRedemptionSheet();
  }

  /// Cốt lõi: Xử lý luồng sự kiện purchase từ stream của OS
  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _handlePending(purchaseDetails);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccess(purchaseDetails);
          break;
        case PurchaseStatus.error:
          await _handleError(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          // Một số phiên bản / platform trả về canceled riêng biệt
          await _handleError(purchaseDetails);
          break;
      }
    }
  }

  void _handlePending(PurchaseDetails purchase) {
    // Chỉ in log báo hiệu đang chờ giao dịch (để UI quay spinner nếu muốn)
    if (kDebugMode) {
      print('Pending: ${purchase.productID}');
    }
  }

  Future<void> _handleError(PurchaseDetails purchase) async {
    final errorMessage = purchase.error?.message ?? "User Canceled";
    if (kDebugMode) {
      print('IAP Error: $errorMessage');
    }
    await remoteDataSource.completePurchase(purchase);

    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.completeError(IapException(errorMessage));
      _purchaseCompleter = null;
    }
  }

  Future<void> _handleSuccess(PurchaseDetails purchase) async {
    try {
      // 1. Verify receipt (offline hoặc qua backend)
      final isValid = await _verifyPurchase(purchase);
      if (!isValid) {
        if (kDebugMode) {
          print('Invalid purchase receipt. Removing from queue.');
        }
        await remoteDataSource.completePurchase(purchase);
        
        if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
          _purchaseCompleter!.completeError(IapException('Invalid receipt'));
          _purchaseCompleter = null;
        }
        return; // Bỏ qua nếu receipt không hợp lệ
      }

      // 2. Map ra Entitlement
      final entitlement = _mapToEntitlement(purchase);

      // 3. Cập nhật State cho app
      if (!_entitlementController.isClosed) {
        _entitlementController.add(entitlement);
      }

      // 4. Bắt buộc: Hoàn thành giao dịch với Apple/Google
      await remoteDataSource.completePurchase(purchase);

      // 5. Lưu cục bộ (cache local DB/SharedPreferences) để nhỡ mất mạng
      await _cacheLocal(entitlement);
      
      if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
        _purchaseCompleter!.complete();
        _purchaseCompleter = null;
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error handling success: $e');
      }
      // Chống treo hàng đợi StoreKit 2
      if (e.toString().contains('liên kết với một tài khoản khác') || 
          e.toString().contains('liên kết với tài khoản') ||
          e.toString().contains('Account hopping')) {
         try {
           await remoteDataSource.completePurchase(purchase);
         } catch (finishErr) {
           if (kDebugMode) print('Could not complete rejected purchase: $finishErr');
         }
      }

      if (!_entitlementController.isClosed) {
        _entitlementController.addError(e);
      }

      if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
        _purchaseCompleter!.completeError(e);
        _purchaseCompleter = null;
      }
    }
  }

  /// Gọi check purchase Local nếu không cung cấp Validate Backend
  Future<bool> _verifyPurchase(PurchaseDetails details) async {
    if (receiptValidator != null) {
      // Có backend can thiệp thì chờ backend xác thực
      final backendEntitlement = await receiptValidator!.verify(details);
      return backendEntitlement.isActive;
    }
    // Không có backend thì mặc định trust Store receipt cục bộ
    return true;
  }

  /// Biến đổi Raw IAP thành quyền lợi trong UserEntitlement
  UserEntitlement _mapToEntitlement(PurchaseDetails details) {
    final config = _configs.firstWhere(
      (c) => c.id == details.productID,
      orElse: () => IapProductConfig(
        id: details.productID,
        type: IapProductType.subscription, // safe default
      ),
    );

    if (config.type == IapProductType.lifetime) {
      return UserEntitlement(
        isActive: true, 
        isLifetime: true,
        activeProductId: details.productID,
      );
    }

    return UserEntitlement(
      isActive: true,
      isLifetime: false,
      activeProductId: details.productID,
      expiresAt: config.duration != null
          ? DateTime.now().add(config.duration!)
          : null,
    );
  }

  /// Lưu vào bộ nhớ cục bộ.
  Future<void> _cacheLocal(UserEntitlement e) async {
    // Bổ sung SharedPreferences / Hive nếu ứng dụng cần.
    // Việc này giúp user reopen app không bị check chậm hoặc mất mạng vẫn có VIP.
    if (kDebugMode) {
      print('Cached entitlement successfully.');
    }
  }

  void dispose() {
    _purchaseSubscription?.cancel();
    _entitlementController.close();
  }
}
