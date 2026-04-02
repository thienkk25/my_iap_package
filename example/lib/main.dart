import 'dart:async';
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
      title: 'IAP Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AllCasesDemoScreen(),
    );
  }
}

class AllCasesDemoScreen extends StatefulWidget {
  const AllCasesDemoScreen({super.key});

  @override
  State<AllCasesDemoScreen> createState() => _AllCasesDemoScreenState();
}

class _AllCasesDemoScreenState extends State<AllCasesDemoScreen> {
  // 1. Khởi tạo Manager
  final IapManager _iapManager = IapManager();
  
  // State cục bộ để stream
  List<IapProduct> _products = [];
  bool _isLoading = true;
  String _statusMessage = 'Đang khởi tạo...';

  // Dùng để demo giao diện Local (giả lập trả về từ Real Stream)
  final StreamController<UserEntitlement> _demoStreamController = StreamController<UserEntitlement>.broadcast();

  @override
  void initState() {
    super.initState();
    _initRealIAP();
    
    // Gắn luồng thực tế vào luồng demo để hợp nhất event hiển thị cho UI
    _iapManager.entitlementStream.listen((event) {
      _demoStreamController.add(event);
    });
  }

  Future<void> _initRealIAP() async {
    try {
      final config = [
        const IapProductConfig(
          id: 'com.example.pro_monthly',
          type: IapProductType.subscription,
          duration: Duration(days: 30),
        ),
        const IapProductConfig(
          id: 'com.example.pro_lifetime',
          type: IapProductType.lifetime,
        ),
      ];

      await _iapManager.init(config: config);
      setState(() => _statusMessage = 'Lấy thông tin gói cước từ store...');
      
      _products = await _iapManager.getProducts();
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Sẵn sàng (${_products.length} sản phẩm)';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Lỗi hệ thống thực (Giả lập sẽ luôn lỗi): $e';
      });
    }
  }

  @override
  void dispose() {
    _demoStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Các Trường Hợp IAP (All Cases)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore (Hầm thực)',
            onPressed: () => _handleAction(
              actionName: 'Khôi phục Mua sắm (Restore)',
              actionFuture: _iapManager.restore(),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- TRƯỜNG HỢP 1: TRẠNG THÁI HIỆN TẠI (ENTITLEMENT STREAM) ---
            _buildSectionTitle('1. Trạng thái Quyền lợi hiện tại'),
            _buildEntitlementCard(),

            const Divider(),

            // --- TRƯỜNG HỢP 2: CÁC SẢN PHẨM REAL TỪ STORE ---
            _buildSectionTitle('2. Cửa hàng (Real API)'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Status: $_statusMessage',
                style: TextStyle(
                  color: _products.isEmpty ? Colors.red : Colors.green,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_products.isEmpty)
              _buildMockProductsFallback()
            else
              _buildRealProductsList(),

            const Divider(),

            // --- TRƯỜNG HỢP 3: MOCK STATE CỦA APP (DEBUG PANEL) ---
            _buildSectionTitle('3. Bảng điều khiển giả lập UI (Debug UI states)'),
            _buildDebugPanel(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildEntitlementCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: StreamBuilder<UserEntitlement>(
        stream: _demoStreamController.stream,
        initialData: UserEntitlement.inactive(),
        builder: (context, snapshot) {
          final entitlement = snapshot.data!;
          
          if (entitlement.isActive) {
            return Column(
              children: [
                const Icon(Icons.workspace_premium, color: Colors.orange, size: 64),
                const SizedBox(height: 16),
                Text(
                  'BẠN ĐANG LÀ THÀNH VIÊN PRO',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (entitlement.isLifetime)
                  const Chip(
                    label: Text('Gói Vĩnh Viễn (Lifetime)'),
                    backgroundColor: Colors.orangeAccent,
                  )
                else ...[
                  Chip(
                    label: Text('Gói Đăng Ký (${entitlement.expiresAt != null ? "Hết hạn: ${entitlement.expiresAt!.toString().substring(0,10)}" : "Không xác định"})'),
                    backgroundColor: Colors.lightGreenAccent,
                  ),
                ],
              ],
            );
          }

          // Case: Inactive
          return Column(
            children: [
              Icon(Icons.lock_outline, color: Colors.grey[400], size: 64),
              const SizedBox(height: 16),
              Text(
                'TÀI KHOẢN MIỄN PHÍ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hiện tại bạn đang dùng bản miễn phí có tính năng hạn chế.',
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRealProductsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.storefront),
            title: Text(product.title),
            subtitle: Text(product.description),
            trailing: ElevatedButton(
              onPressed: () => _handleAction(
                actionName: 'Mua gói ${product.title}', 
                actionFuture: _iapManager.buy(product),
              ),
              child: Text(product.price),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMockProductsFallback() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️ Không thể tải sản phẩm. Lưu ý:'),
          const Text('1. Chạy trên máy ảo sẽ LUÔN lỗi bước này.'),
          const Text('2. Yêu cầu gắn thẻ Bundle ID trùng với App Store Connect/Play Console.'),
          const Text('3. Phải set up config Product ID trên store trước.'),
          const SizedBox(height: 16),
          const Text('Do đó, bạn hảy dùng các nút mock bên dưới để test Giao diện nhé!', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDebugPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('Giả lập: Trở về Miễn phí'),
            onPressed: () {
              _demoStreamController.add(UserEntitlement.inactive());
            },
            style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: const Text('Giả lập: Đã mua gói Tháng'),
            onPressed: () {
              _demoStreamController.add(UserEntitlement(
                isActive: true, 
                isLifetime: false, 
                expiresAt: DateTime.now().add(const Duration(days: 30)),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.all_inclusive),
            label: const Text('Giả lập: Đã mua Vĩnh Viễn'),
            onPressed: () {
              _demoStreamController.add(const UserEntitlement(
                isActive: true, 
                isLifetime: true,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.error_outline),
            label: const Text('Giả lập: Mua lỗi (Try/Catch)'),
            onPressed: () async {
              try {
                // Ép throw ra lỗi để demo
                throw const IapFailure('Người dùng đã thoát cửa sổ thanh toán (User Canceled).');
              } catch (e) {
                if (!mounted) return;
                _showErrorDialog('Lỗi giả lập thanh toán', e.toString());
              }
            },
            style: ElevatedButton.styleFrom(foregroundColor: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction({required String actionName, required Future actionFuture}) async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đang xử lý: $actionName...')));
      await actionFuture;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Thành công: $actionName')));
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Lỗi: $actionName', e.toString());
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          )
        ],
      ),
    );
  }
}
