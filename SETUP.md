# ⚙️ Platform Setup Guide

Integrating In-App Purchases (IAP) requires explicit native configuration. 
**This entire setup requires you to use the REAL App Store Connect and Google Play Console.**

---

## 🍎 iOS Setup (App Store)

### 1. Enable In-App Purchase Capability
1. Open your project in `Xcode` (`ios/Runner.xcworkspace`).
2. Navigate to your target > **Signing & Capabilities**.
3. Click `+ Capability` and add **In-App Purchase**.

### 2. Create Products (App Store Connect)
1. Log in to [App Store Connect](https://appstoreconnect.apple.com/).
2. Go to **My Apps** > your app > **Features** > **In-App Purchases**.
3. Create your corresponding IDs. Make sure these EXACTLY match your code configs.
   *Example:*
   - `com.example.pro_lifetime` (Type: Non-Consumable)
   - `com.example.pro_monthly` (Type: Auto-Renewable Subscription)

> **⚠️ WARNING:** 
> IDs MUST match what you supply in `IapProductConfig`.

### 3. Setup Offers (Optional)
If you plan to use Introductory Offers, Promotional Offers, or Offer Codes in iOS:
1. **Introductory Offers**: Go to your Subscription > **Subscription Prices** > **Introductory Offers** (+). Set your trial or discounted price. This applies automatically.
2. **Promotional Offers**: Go to your Subscription > **Promotional Offers** (+). Create a Reference Name and a **Promotional Offer ID** (this is your `offerIdentifier`). You will also need to generate a Subscription Key in Users and Access -> Keys.
3. **Offer Codes**: Let users redeem codes outside the app. Go to your Subscription > **Offer Codes** (+) and specify your rules and codes. Use `presentCodeRedemptionSheet()` in your app to let users redeem them.

### 3. Agreements & Sandbox
1. Complete all **Agreements, Tax, and Banking** documents on App Store Connect. (If this is not done, IAP fetches will silently fail in Xcode).
2. Create Sandbox Tester accounts. Log into them via your physical iPhone Settings > App Store > Sandbox Account to test purchases without a credit card.

---

## 🤖 Android Setup (Google Play)

### 1. Upload App Bundle
You **must** upload the actual `.aab` file to the Google Play Console (Internal Testing track is fine) before you can create IAPs.

### 2. Create Products
1. In the Play Console, go to **Monetize** > **Products**.
2. Depending on your needs:
   - Create an **In-app product** for Lifetime modules.
   - Create a **Subscription** (Base plan + Offers) for Monthly/Yearly modules.

### 3. Test Accounts
1. Go to **Setup** > **License Testing**.
2. Add the email addresses of the testers. Doing this allows testers to "purchase" items via a test card for free.

### 4. Application Signing
When testing on Android, the local build **must** be signed with the exact release/debug keystore that matches the fingerprint registered in Play Console.

---

## 🔐 Backend Validation (Highly Recommended)

Relying purely on offline cache for Auto-Renewable Subscriptions means your app won't know if a user cancelled their subscription via OS Settings.

To resolve this safely, implement the `ReceiptValidator` interface provided in the package:

```text
App → Complete Purchase Details
↓
Package calls ReceiptValidator.verify(details)
↓
Your App sends Token to Your Custom Backend
↓
Your Backend talks to Apple/Google to check actual status
↓
Your Backend saves in DB and returns {isActive: true, expiresAt: ...}
↓
Package unblocks entitlement locally!
```

---

## ⚠️ Common Troubleshooting

### Q: Why is `_products` an empty array during `getProducts`?
- Your Bundle ID in `pubspec.yaml` / Xcode does not match App Store / Play Console.
- You did not sign all Paid App tax agreements on Apple.

### Q: Why does the purchase fail immediately?
- iOS: You forgot to add the IAP capability in Xcode.
- Android: Your local app build is not uploading keys properly or not signed correctly.

### Q: Why does Restore return an error?
- You are trying to restore on a fresh Google/Apple Account with zero purchase history.
- Ensure you used the Sandbox Apple ID that originally made the purchase.
