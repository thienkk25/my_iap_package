# 📦 my_iap_package

A lightweight, framework-agnostic wrapper around `in_app_purchase`.

⚡ Designed to be:

* Reusable across ANY app (not just VPN)
* Independent (NO Bloc, Provider, Riverpod)
* Easily pluggable into any architecture

---

# 🚀 Features

* ✅ Supports lifetime + subscription
* ✅ Pure Dart (no state management dependency)
* ✅ Stream-based updates
* ✅ Config-driven (no hardcode product IDs)
* ✅ Easy to reuse across projects

---

# 📥 Installation

```yaml
dependencies:
  my_iap_package:
    path: ../my_iap_package
```

---

# ⚠️ Important Setup

👉 You MUST complete platform setup before using

See: `SETUP.md`

---

# 🧠 Usage (No Bloc / No Provider)

## 1. Define Products

```dart
final config = [
  IapProductConfig(
    id: 'pro_lifetime',
    type: IapProductType.lifetime,
  ),
  IapProductConfig(
    id: 'pro_monthly',
    type: IapProductType.subscription,
    duration: Duration(days: 30),
  ),
];
```

---

## 2. Init

```dart
final iap = IapManager();

await iap.init(config: config);
```

---

## 3. Load Products

```dart
final products = await iap.getProducts();
```

---

## 4. Buy

```dart
await iap.buy(products.first);
```

---

## 5. Restore

```dart
await iap.restore();
```

---

## 6. Listen State (Stream)

```dart
iap.entitlementStream.listen((entitlement) {
  if (entitlement.isActive) {
    print('User has access');
  }
});
```

---

# 🧾 Core Models

## Product Config

```dart
enum IapProductType {
  lifetime,
  subscription,
}

class IapProductConfig {
  final String id;
  final IapProductType type;
  final Duration? duration;

  const IapProductConfig({
    required this.id,
    required this.type,
    this.duration,
  });
}
```

---

## Entitlement (Unified State)

```dart
class UserEntitlement {
  final bool isActive;
  final bool isLifetime;
  final DateTime? expiresAt;

  const UserEntitlement({
    required this.isActive,
    required this.isLifetime,
    this.expiresAt,
  });
}
```

---

# ⚙️ Core API

```dart
class IapManager {
  Future<void> init({required List<IapProductConfig> config});

  Future<List<IapProduct>> getProducts();

  Future<void> buy(IapProduct product);

  Future<void> restore();

  Stream<UserEntitlement> get entitlementStream;
}
```

---

# 🔐 Optional: Receipt Validation

You can inject your own validator:

```dart
abstract class ReceiptValidator {
  Future<UserEntitlement> verify(PurchaseDetails purchase);
}
```

---

# 🧱 Architecture

```
Your App
   ↓
IapManager
   ↓
IapProvider (interface)
   ↓
in_app_purchase
```

---

# ⚡ Best Practices

### ✅ Do

* Call `init()` once at app start
* Always listen to `entitlementStream`
* Restore purchases on launch
* Use backend validation for production

### ❌ Avoid

* Hardcoding product IDs inside package
* Mixing UI logic inside IAP layer
* Ignoring purchase stream

---

# 🧪 Minimal Example

```dart
final iap = IapManager();

await iap.init(config: config);

final products = await iap.getProducts();

await iap.buy(products.first);

// Listen anywhere (no bloc needed)
iap.entitlementStream.listen((e) {
  print(e.isActive);
});
```