import 'package:flutter/material.dart';
import 'package:my_iap_package/my_iap_package.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IAP Package Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SubscriptionScreen(),
    );
  }
}

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
      body: Column(
        children: [
          // 5. Giao diện hiển thị Trạng Thái Tài Khoản (Lắng nghe Stream)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade100],
              ),
            ),
            child: StreamBuilder<UserEntitlement>(
              stream: _iapManager.entitlementStream,
              initialData: UserEntitlement.inactive(),
              builder: (context, snapshot) {
                final entitlement = snapshot.data!;

                if (entitlement.isActive) {
                  return Column(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        'TÀI KHOẢN PREMIUM',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entitlement.isLifetime
                            ? 'Gói mua đứt Vĩnh Viễn'
                            : 'Gói đăng ký gia hạn hàng tháng',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      if (entitlement.expiresAt != null)
                        Text(
                          'Hết hạn: ${entitlement.expiresAt!.toIso8601String().substring(0, 10)}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                    ],
                  );
                }

                return Column(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: Colors.black54,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TÀI KHOẢN MIỄN PHÍ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hãy mua gói cước bên dưới để mở khoá tính năng.',
                    ),
                  ],
                );
              },
            ),
          ),

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
          const SizedBox(height: 8),

          // 6. Giao diện hiển thị Cửa Hàng (Sản phẩm IAP)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                ? const Center(child: Text('Không tải được gói cước nào.'))
                : ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            product.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(product.description),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Đang xử lý mua: ${product.title}...',
                                    ),
                                  ),
                                );
                                // 7. Tiến hành giao dịch
                                await _iapManager.buy(product);
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi giao dịch: $e')),
                                );
                              }
                            },
                            child: Text(
                              product.price,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
