import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/error/exceptions.dart';
import 'iap_remote_datasource.dart';

/// Bản giả lập của `IapRemoteDataSource` dùng để test IAP trên Máy ảo (Simulator/Emulator)
class FakeIapRemoteDataSource implements IapRemoteDataSource {
  final StreamController<List<PurchaseDetails>> _purchaseStreamController =
      StreamController<List<PurchaseDetails>>.broadcast();

  final List<PurchaseDetails> _purchasedItems = [];

  // Kho dữ liệu ảo chứa các gói tĩnh để trả về thông tin chi tiết đẹp hơn
  final Map<String, ProductDetails> _fakeStoreDB = {
    'com.example.pro_monthly': ProductDetails(
      id: 'com.example.pro_monthly',
      title: 'Pro Tháng (Tự động gia hạn)',
      description: 'Mở khóa toàn bộ tính năng cao cấp trong 30 ngày.',
      price: '₫49.000',
      rawPrice: 49000,
      currencyCode: 'VND',
    ),
    'com.example.pro_yearly': ProductDetails(
      id: 'com.example.pro_yearly',
      title: 'Pro Năm (Tiết kiệm)',
      description: 'Gói siêu tiết kiệm theo năm. Thanh toán một lần dùng 12 tháng.',
      price: '₫399.000',
      rawPrice: 399000,
      currencyCode: 'VND',
    ),
    'com.example.pro_lifetime': ProductDetails(
      id: 'com.example.pro_lifetime',
      title: 'Pro Vĩnh Viễn (Mua 1 lần)',
      description: 'Sở hữu trọn đời không bao giờ phải đóng thêm phí.',
      price: '₫999.000',
      rawPrice: 999000,
      currencyCode: 'VND',
    ),
    'com.example.error_item': ProductDetails(
      id: 'com.example.error_item',
      title: 'Gói thử nghiệm LỖI',
      description: 'Nhấn vào đây để xem hệ thống bắt Lỗi (như kẹt thanh toán).',
      price: '₫0',
      rawPrice: 0,
      currencyCode: 'VND',
    ),
  };

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseStreamController.stream;

  @override
  Future<bool> isAvailable() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 1500),
    ); // Rút dữ liệu mất 1.5s

    List<ProductDetails> foundProducts = [];
    List<String> notFoundIds = [];

    for (var id in identifiers) {
      if (_fakeStoreDB.containsKey(id)) {
        foundProducts.add(_fakeStoreDB[id]!);
      } else {
        // Fallback tự sinh data nếu đưa ID lạ vào
        foundProducts.add(
          ProductDetails(
            id: id,
            title: 'Gói lạ: $id',
            description: 'Không có dữ liệu trong DB giả lập',
            price: '₫???.???',
            rawPrice: 0,
            currencyCode: 'VND',
          ),
        );
      }
    }

    // Luôn sắp xếp theo giá thâp tới cao để UI render đẹp
    foundProducts.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

    return ProductDetailsResponse(
      productDetails: foundProducts,
      notFoundIDs: notFoundIds,
    );
  }

  @override
  Future<bool> buyProduct(ProductDetails productDetails) async {
    // 1. Nếu đây là gói Test Bắn lỗi:
    if (productDetails.id == 'com.example.error_item') {
      await Future.delayed(const Duration(seconds: 1));
      throw IapException('KHÁCH HÀNG ĐÃ HUỶ THANH TOÁN (Mock Error Test)');
    }

    // 2. Chờ user thao tác mua hàng giả lập:
    await Future.delayed(const Duration(seconds: 2));

    final fakePurchaseDetails = PurchaseDetails(
      productID: productDetails.id,
      purchaseID: 'FAKE_TRANSACTION_${DateTime.now().millisecondsSinceEpoch}',
      status: PurchaseStatus.purchased,
      transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
      verificationData: PurchaseVerificationData(
        localVerificationData: 'fake_local_data',
        serverVerificationData: 'fake_server_data',
        source: 'fake_store',
      ),
    );

    _purchasedItems.add(fakePurchaseDetails);

    // Bắn event mua thành công vào stream thay vì chỉ ném return
    _purchaseStreamController.add([fakePurchaseDetails]);
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    await Future.delayed(const Duration(seconds: 2)); // Chờ load

    if (_purchasedItems.isEmpty) {
      // GIẢ LẬP KỊCH BẢN: Người dùng vừa cài lại app (chưa bấm mua gì trong phiên này)
      // Ta cố tình đẩy về 1 lệnh mua "Lifetime" trong quá khứ lúc họ click Restore để thấy UI nhảy.
      final fakeOldPurchase = PurchaseDetails(
        productID: 'com.example.pro_lifetime',
        purchaseID: 'FAKE_PAST_RESTORE_ID_125',
        status: PurchaseStatus.restored,
        transactionDate: DateTime.now()
            .subtract(const Duration(days: 365))
            .millisecondsSinceEpoch
            .toString(),
        verificationData: PurchaseVerificationData(
          localVerificationData: 'fake_local_data',
          serverVerificationData: 'fake_server_data',
          source: 'fake_store',
        ),
      );
      _purchaseStreamController.add([fakeOldPurchase]);
      return;
    }

    final restoredItems = _purchasedItems.map((p) {
      return PurchaseDetails(
        productID: p.productID,
        purchaseID: p.purchaseID,
        status: PurchaseStatus.restored,
        transactionDate: p.transactionDate,
        verificationData: p.verificationData,
      );
    }).toList();

    _purchaseStreamController.add(restoredItems);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
