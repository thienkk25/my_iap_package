# ⚙️ Platform Setup Guide

This setup is REQUIRED.

---

# 🍎 iOS Setup

## 1. Enable In-App Purchase

* Open Xcode
* Signing & Capabilities
* Add: In-App Purchase

---

## 2. Create Products (App Store Connect)

Create your own IDs (example):

* pro_lifetime
* pro_monthly
* pro_yearly

⚠️ IDs MUST match your config in code

---

## 3. Agreements

* Complete Paid Apps Agreement
* Add bank + tax

---

## 4. Sandbox Account

* Create test Apple ID
* Login on device

---

# 🤖 Android Setup

## 1. Upload App

* Upload to Play Console (internal testing ok)

---

## 2. Create Products

* Monetization → Products

Create:

* In-app product (lifetime)
* Subscriptions

---

## 3. Test Accounts

* Add license testers

---

## 4. Signing

* Use RELEASE keystore

---

# 🔐 Backend Validation (Recommended)

```text
App → Purchase
→ Send receipt to backend
→ Verify with store
→ Save DB
→ Return entitlement
```

---

# ⚠️ Common Issues

### Products not loading

* Wrong product ID
* App not uploaded
* Store not ready

### Purchase fails

* Missing capability (iOS)
* Debug build (Android)

### Restore fails

* No previous purchase
* Wrong account

---

# ✅ Checklist

* [ ] Product IDs match
* [ ] IAP enabled
* [ ] App uploaded
* [ ] Test account ready
* [ ] Listener implemented

---

# 🎯 Ready

You can now use `my_iap_package` in ANY Flutter app 🚀

You are ready to use `my_iap_package` 🚀
