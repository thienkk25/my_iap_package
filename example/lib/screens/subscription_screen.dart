import 'package:flutter/material.dart';
import 'package:my_iap_package/my_iap_package.dart';

import '../widgets/entitlement_status_view.dart';
import '../widgets/product_card.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // 1. Khởi tạo Manager
  final IapManager _iapManager = IapManager();

  List<IapProduct> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initIap();
  }

  Future<void> _initIap() async {
    try {
      // 2. Định nghĩa danh sách các gói cước được cấp phép
      final config = [
        const IapProductConfig(
          id: 'com.example.pro_monthly',
          type: IapProductType.subscription,
          duration: Duration(days: 30),
        ),
        const IapProductConfig(
          id: 'com.example.pro_yearly',
          type: IapProductType.subscription,
          duration: Duration(days: 365),
        ),
        const IapProductConfig(
          id: 'com.example.pro_lifetime',
          type: IapProductType.lifetime,
        ),
        const IapProductConfig(
          id: 'com.example.error_item',
          type: IapProductType.lifetime, // Any type since it will fail
        ),
      ];

      // 3. Khởi tạo và fetch thông tin gói cước
      await _iapManager.init(config: config);
      _products = await _iapManager.getProducts();

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khởi tạo IAP: $e')));
      setState(() => _isLoading = false);
    }
  }

  void _handleBuyProduct(IapProduct product) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang xử lý mua (Auto-IntroOffer): ${product.title}...'),
        ),
      );
      // 7. Tiến hành giao dịch bình thường (bao gồm tự động Intro Offer)
      await _iapManager.buy(product);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi giao dịch: $e')),
      );
    }
  }

  void _handleBuyPromotionalOffer(IapProduct product) async {
    // Demo tạo signature giả lập (thực tế server của bạn sẽ trả về signature này qua API)
    final mockSignature = PromotionalOfferSignature(
      keyIdentifier: 'YOUR_KEY_ID',
      nonce: 'A1B2C3D4-E5F6-47A8-9B0C-1D2E3F4A5B6C',
      signature: 'MEYCIQ...',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang mua Promotional Offer cho ${product.title}...'),
        ),
      );
      await _iapManager.buyPromotionalOffer(
        product,
        'discount_identifier',
        mockSignature,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi giao dịch: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nâng cấp Tài Khoản'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('Khôi phục'),
            onPressed: () async {
              try {
                // 4. Test hàm Restore
                await _iapManager.restore();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xử lý khôi phục hoàn tất!')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Lỗi khôi phục: $e')));
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // 5. Giao diện hiển thị Trạng Thái Tài Khoản
          EntitlementStatusView(entitlementStream: _iapManager.entitlementStream),

          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Danh Sách Gói Cước',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '💡 Mẹo: Introductory Offers (Dùng thử miễn phí/Giảm giá tháng đầu) '
              'được hệ điều hành tự động áp dụng khi user nhấn nút mua, '
              'không cần gọi API riêng.',
              style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                  fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),

          // 6. Giao diện hiển thị Cửa Hàng (Sản phẩm IAP)
          if (_isLoading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator()))
          else if (_products.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Không tải được gói cước nào.')))
          else
            ..._products.map((product) {
              final isSub = product.id == 'com.example.pro_monthly' ||
                  product.id == 'com.example.pro_yearly';
              return ProductCard(
                product: product,
                onBuy: () => _handleBuyProduct(product),
                onBuyPromotional: isSub
                    ? () => _handleBuyPromotionalOffer(product)
                    : null,
              );
            }),

          const SizedBox(height: 24),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tính năng khác (iOS)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Nhập Mã Ưu Đãi (Offer Codes)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () async {
                try {
                  // Mở bottom sheet của iOS để nhập mã trúng thưởng/giảm giá Offer Codes
                  await _iapManager.presentCodeRedemptionSheet();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
