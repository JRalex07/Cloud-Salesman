# Security Specification: Salesman App Firestore Rules

This document outlines the security invariants, validation targets, and test payloads ("Dirty Dozen") designed to audit and harden the firestore rules for the Salesman App ecosystem.

## 1. Data Invariants and Integrity Rules

### core/salesmen
- **Owner-Exclusive Isolation**: A salesman user can read their own profile document but cannot read other salesmen's profiles.
- **Strict Keys & Schema Validation**:
  - Profile documents contain identification keys (`uid`, `email`, `phone`, `role`, `assignedRouteId`, `assignedArea`, `isActive`, `createdAt`, `lastLogin`, `fcmToken`).
  - Only Admins can create or delete salesmen profiles.
  - A salesman can only update their own profile's `fcmToken` and `lastLogin` fields (e.g., during login or logout). General modifications to assigned routes, roles, or active status are strictly forbidden.

### core/attendance
- **Sub-Resource Authorization**: Only the owner salesman (where `salesmanId == uid`) can read, write, or view their attendance records.
- **Terminal State Lock**: Once status is marked "Present" and checkout is completed, it should not be mutated or falsified by the salesman.
- **Transactional Atomicity**: Checking in or out requires atomic synchronization with the `tracking_live/{salesmanId}` document so state is consistent.

### core/visits
- **Check-In Isolation**: Salesmen can only check-in and checkout of shops under their own subcollection (`visits/{visitId}`).
- **Key Whitelisting**: On checkout, the salesman can only update specific completed actions (`checkOutTime`, `checkOutLatitude`, `checkOutLongitude`, `distanceFromShop`, `notes`, `status`). All other fields remain immutable.

### core/tracking & core/tracking_live
- **Location Spoofing Guard**: Salesmen can only publish tracking updates for their own `uid`.
- **Resource Exhaustion Block**: Tracking strings are bounded under severe size restrictions (accuracy, speed, battery) to prevent high DB read/write costs.

### core/shops
- **Directory Authenticity**: Anyone signed in can read shops, but only active salesmen or admins can register new shops or update coordinates/info.

### core/orders & core/timeline
- **Actor Polyfill**: Orders can be created either by a Customer (matching `userId == uid`) or by an Active Salesman (matching `salesmanId == uid`).
- **Update Lock**: Once an order status is placed and completed/cancelled, subsequent updates are locked unless executed by an admin.
- **Stock Depletion Authorization**: To place orders, active salesmen must be allowed to decrement/update the `stock` field of `products/{id}` atomically, but cannot modify prices, descriptions, images, or names of products.

---

## 2. The "Dirty Dozen" Payloads (Exploit Vector Audits)

The following payloads represent real exploit vectors that our rules must reject:

### Payload 1: Salesman Role Escalation
An authenticated salesman attempts to update their user role to `admin` or set `isActive = true` when they were deactivated.
- **Path**: `salesmen/salesman_123`
- **Payload**: `{"role": "admin", "isActive": true}`
- **Expected Outcome**: `PERMISSION_DENIED`

### Payload 2: Cross-Salesman Reading
A logged-in salesman (`salesman_abc`) attempts to read the attendance logs of `salesman_xyz`.
- **Path**: `salesmen/salesman_xyz/attendance/att_789`
- **Operation**: `get`
- **Expected Outcome**: `PERMISSION_DENIED`

### Payload 3: Spoofed Position Publication
A user `salesman_123` attempts to write on-duty live tracking position details into document ID `salesman_999`.
- **Path**: `tracking_live/salesman_999`
- **Payload**: `{"latitude": 1.23, "longitude": 103.45, "salesmanId": "salesman_999"}`
- **Expected Outcome**: `PERMISSION_DENIED`

### Payload 4: Unverified User Session
An authenticated user whose email is not verified attempts to check-in or start duty.
- **Path**: `salesmen/unverified_123/attendance/att_new`
- **Expected Outcome**: `PERMISSION_DENIED`

### Payload 5: Product Price Tampering (Stock Bypass)
A salesman placing an order tries to modify a product's price to `$0.01` in `/products/{productId}` under the guise of stock updating.
- **Path**: `products/prod_iphone`
- **Payload**: `{"price": 0.01, "stock": 10}`
- **Expected Outcome**: `PERMISSION_DENIED` (only `stock` can be modified by salesmen)

### Payload 6: Order Status Terminal Hijacking
A customer or salesperson attempts to override a cancelled order back to `Placed` or change internal billing notes.
- **Path**: `orders/ord_cancelled_999`
- **Payload**: `{"orderStatus": "Placed"}`
- **Expected Outcome**: `PERMISSION_DENIED`

### Payload 7: Orphaned Timeline Write
A salesman attempts to register a fake timeline entry under an order they do not own or didn't place.
- **Path**: `orders/ord_foreign_001/timeline/fake_tim_99`
- **Expected Outcome**: `PERMISSION_DENIED`

### Payload 8: Shop Creation Deletion
An anonymous visitor attempts to delete or alter physical shop positions.
- **Path**: `shops/shop_999`
- **Operation**: `delete`
- **Expected Outcome**: `PERMISSION_DENIED`

### Payload 9: Ghost Field Injection
A salesman updates a visit check-out sheet and attempts to sneak in an unvalidated field (`isApprovedByManager: true`).
- **Path**: `salesmen/salesman_123/visits/visit_456`
- **Payload**: `{"notes": "Done", "isApprovedByManager": true}`
- **Expected Outcome**: `PERMISSION_DENIED`

### Payload 10: Negative Stock Injection
A malicious agent attempts to write a product stock update with string values or out-of-bound numbers.
- **Path**: `products/prod_xyz`
- **Payload**: `{"stock": "many"}`
- **Expected Outcome**: `PERMISSION_DENIED`

### Payload 11: Cross-User Private Notification Access
User A attempts to list user B's notifications list.
- **Path**: `salesmen/salesman_xyz/notifications`
- **Operation**: `list`
- **Expected Outcome**: `PERMISSION_DENIED`

### Payload 12: Admin Auth Spoofing
An attacker with email `admin@company.com` sets up custom claims on their client token to access administrative routes.
- **Path**: `admins/attacker_uid`
- **Expected Outcome**: `PERMISSION_DENIED` (Custom token claims are ignored; access is strictly based on trusted Firestore collection lookup `/admins/{uid}`)
