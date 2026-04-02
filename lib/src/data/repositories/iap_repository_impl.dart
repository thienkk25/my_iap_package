import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/error/exceptions.dart';
import '../../domain/entities/iap_product.dart';
import '../../domain/entities/iap_product_config.dart';
import '../../domain/entities/iap_product_type.dart';
import '../../domain/entities/user_entitlement.dart';
import '../../domain/repositories/iap_repository.dart';
import '../../domain/repositories/receipt_validator.dart';
import '../datasources/iap_remote_datasource.dart';

class IapRepositoryImpl implements IapRepository {
  final IapRemoteDataSource remoteDataSource;
  final ReceiptValidator? receiptValidator;

  final _entitlementController = StreamController<UserEntitlement>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<IapProductConfig> _configs = [];

  IapRepositoryImpl({
    required this.remoteDataSource,
    this.receiptValidator,
  });

  @override
  Stream<UserEntitlement> get entitlementStream => _entitlementController.stream;

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

  @override
  Future<void> buy(IapProduct product) async {
    if (product.rawDetails is! ProductDetails) {
      throw IapException('Invalid product details format.');
    }
    
    final success = await remoteDataSource.buyProduct(product.rawDetails as ProductDetails);
    if (!success) {
      throw IapException('Failed to initiate purchase flow.');
    }
  }

  @override
  Future<void> restore() async {
    await remoteDataSource.restorePurchases();
  }

  /// Hàm xử lý luồng sự kiện purchase từ stream của OS
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Đang chờ giao dịch, có thể update UI ở app level thông qua bloc (ở đây chỉ emit data)
        continue;
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Giao dịch lỗi
        throw IapException('Transaction failed: ${purchaseDetails.error?.message}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        
        try {
          // Verify receipt (offline hoặc qua backend)
          final entitlement = await _verifyPurchase(purchaseDetails);
          
          // Cập nhật State cho app
          if (!_entitlementController.isClosed) {
            _entitlementController.add(entitlement);
          }
          
          // Hoàn thành giao dịch (Bắt buộc trên iOS và Android)
          await remoteDataSource.completePurchase(purchaseDetails);
        } catch (e) {
          throw IapException('Verification failed: $e');
        }
      }
    }
  }

  /// Stub mặc định cho việc gọi check purchase Local nếu không cung cấp Validate Backend
  Future<UserEntitlement> _verifyPurchase(PurchaseDetails details) async {
    if (receiptValidator != null) {
      return await receiptValidator!.verify(details);
    }
    
    // Fallback: local trust mechanism
    final config = _configs.firstWhere(
      (c) => c.id == details.productID,
      orElse: () => IapProductConfig(
        id: details.productID, 
        type: IapProductType.subscription, // safe default
      ),
    );

    return UserEntitlement(
      isActive: true,
      isLifetime: config.type == IapProductType.lifetime,
      expiresAt: config.duration != null 
          ? DateTime.now().add(config.duration!) 
          : null,
    );
  }

  // Cần huỷ luồng khi app tắt nếu thiết kế theo singleton/service (tuỳ implementation trong app)
  void dispose() {
    _purchaseSubscription?.cancel();
    _entitlementController.close();
  }
}
