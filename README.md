# 📦 my_iap_package

A modern, lightweight, and framework-agnostic wrapper around Flutter's `in_app_purchase` package. 

Built with **Clean Architecture** principles, this package provides a bulletproof foundation for handling In-App Purchases, Subscriptions, and robust error management without depending on any specific state-management library (No Bloc, No Provider required).

---

## ⚡ Features

* ✅ **Clean Architecture:** Strictly separated into Domain, Data, and Presentation/Manager layers.
* ✅ **Zero State-Management Dependency:** Pure Dart implementation. Easily pluggable into BLoC, Riverpod, Provider, or GetX.
* ✅ **Robust Stream Handling:** Completely bulletproof `purchaseStream` listener ensuring zero dropped transactions, even during app crashes.
* ✅ **Config-driven:** Avoid hardcoded IDs. Dynamically load Subscription and Lifetime logic.
* ✅ **Custom Error Handling:** Strict exception propagation (`IapException`, `IapFailure`) making UI catch blocks highly predictable.

---

## 📥 Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  my_iap_package:
    git:
      url: https://github.com/thienkk25/my_iap_package.git
      ref: main
```

> **⚠️ CRITICAL: Platform Setup**
> You **MUST** complete Apple App Store and Google Play Console setup before hitting production.
> See: [SETUP.md](SETUP.md) for detailed instructions.

---

## 🧠 Usage (Production Ready)

### 1. Define Products

Create a configuration listing your authorized product IDs.

```dart
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
```

### 2. Initialize the Manager

```dart
final iapManager = IapManager();

// Initialize with config
await iapManager.init(config: config);
```

### 3. Load Store Products

```dart
final products = await iapManager.getProducts();
```

### 4. Listen to the Entitlement Stream

This is the **only** source of truth you need for your UI.

```dart
// Listen to errors independently
iapManager.entitlementStream.listen(
  (_) {},
  onError: (error) {
    print('Transaction Failed: $error');
  },
);

// StreamBuilder in UI
StreamBuilder<UserEntitlement>(
  stream: iapManager.entitlementStream,
  initialData: UserEntitlement.inactive(),
  builder: (context, snapshot) {
    if (snapshot.data!.isActive) {
      return Text("PRO MEMBER UNLOCKED!");
    }
    return Text("FREE TIER");
  }
)
```

### 5. Buy & Restore & Offers

```dart
// Trigger a normal purchase (Introductory offers & Trials are handled automatically by the OS)
await iapManager.buy(products.first);

// Trigger a Promotional Offer purchase (iOS only - requires signature from backend)
await iapManager.buyPromotionalOffer(
  products.first,
  'promo_discount_identifier',
  PromotionalOfferSignature(
    keyIdentifier: '...',
    nonce: '...',
    signature: '...',
    timestamp: 123456789,
  ),
);

// Present Offer Code Redemption Sheet (iOS 14+ only)
await iapManager.presentCodeRedemptionSheet();

// Restore past purchases
await iapManager.restore();
```

---

## 🧱 Architecture Details

This package is meticulously divided into standard Clean Architecture folders:

* `core/`: Custom exception bounds (`IapException`) and abstract `UseCase` mappings.
* `domain/`: Business entities (`UserEntitlement`, `IapProduct`) and Repository contracts.
* `data/`: In-depth `in_app_purchase` API interaction (`IapRemoteDataSourceImpl` & `FakeIapRemoteDataSource`), alongside robust mapping/verification logic inside `IapRepositoryImpl`.
* `presentation/`: Exposes `IapManager`, acting as a single Facade that auto-injects data dependencies into UseCases.

---

## 🔐 Optional: Backend Receipt Validation

By default, the package maps local receipts automatically. However, for real Production apps, you shouldn't blindly trust client data. Inject your custom Validator to ping your Database/Server:

```dart
class MyServerValidator implements ReceiptValidator {
  @override
  Future<UserEntitlement> verify(dynamic purchaseData) async {
    // 1. Send purchaseData (Receipt/Token) to your Node/Python server
    // 2. Return true Entitlement from server
  }
}

final manager = IapManager(validator: MyServerValidator());
```

---

*For detailed UI implementation and showcasing, please refer to the `example/` folder included in this setup.*
