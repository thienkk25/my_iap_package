import 'package:flutter/material.dart';
import 'package:my_iap_package/my_iap_package.dart';

class ProductCard extends StatelessWidget {
  final IapProduct product;
  final VoidCallback onBuy;
  final VoidCallback? onBuyPromotional;

  const ProductCard({
    super.key,
    required this.product,
    required this.onBuy,
    this.onBuyPromotional,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(product.description),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: onBuy,
                  child: Text(
                    product.price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            // Hiển thị nút mua Promotional Offer nếu được cung cấp callback
            if (onBuyPromotional != null) ...[
              const Divider(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.local_offer, size: 18),
                  label: const Text(
                    'Mua Khuyến Mãi (Promotional Offer)',
                    style: TextStyle(fontSize: 13),
                  ),
                  onPressed: onBuyPromotional,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '* Yêu cầu Signature giả lập từ Server để kích hoạt',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
