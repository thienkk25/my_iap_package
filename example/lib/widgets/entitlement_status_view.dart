import 'package:flutter/material.dart';
import 'package:my_iap_package/my_iap_package.dart';

class EntitlementStatusView extends StatelessWidget {
  final Stream<UserEntitlement> entitlementStream;

  const EntitlementStatusView({
    super.key,
    required this.entitlementStream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade100],
        ),
      ),
      child: StreamBuilder<UserEntitlement>(
        stream: entitlementStream,
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
    );
  }
}
