import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../util/vn_time.dart';

enum SubscriptionPurchaseResult { storeStarted, mockActivated, unavailable }

class StoreProductSnapshot {
  final String id;
  final String title;
  final String description;
  final String price;

  const StoreProductSnapshot({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });
}

/// Trạng thái WonderLens Plus trên thiết bị.
///
/// Pha hiện tại ưu tiên StoreKit / Google Play Billing qua `in_app_purchase`.
/// Nếu product IDs chưa tồn tại trên Store (dev/internal), paywall vẫn có đường
/// mock rõ ràng để kiểm thử UX mà không thu tiền thật.
class SubscriptionState {
  final bool isPremium;
  final String? productId;
  final DateTime? activatedAt;
  final String source;
  final bool storeAvailable;
  final bool loadingStore;
  final bool purchasePending;
  final Map<String, StoreProductSnapshot> products;
  final Set<String> notFoundIds;
  final String? storeMessage;

  const SubscriptionState({
    required this.isPremium,
    this.productId,
    this.activatedAt,
    this.source = 'none',
    this.storeAvailable = false,
    this.loadingStore = false,
    this.purchasePending = false,
    this.products = const <String, StoreProductSnapshot>{},
    this.notFoundIds = const <String>{},
    this.storeMessage,
  });

  const SubscriptionState.inactive() : this(isPremium: false);

  String get statusLabel =>
      isPremium ? 'WonderLens Plus đang bật' : 'Chưa bật Plus';

  SubscriptionState copyWith({
    bool? isPremium,
    String? productId,
    DateTime? activatedAt,
    String? source,
    bool? storeAvailable,
    bool? loadingStore,
    bool? purchasePending,
    Map<String, StoreProductSnapshot>? products,
    Set<String>? notFoundIds,
    Object? storeMessage = _sentinel,
  }) {
    return SubscriptionState(
      isPremium: isPremium ?? this.isPremium,
      productId: productId ?? this.productId,
      activatedAt: activatedAt ?? this.activatedAt,
      source: source ?? this.source,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      loadingStore: loadingStore ?? this.loadingStore,
      purchasePending: purchasePending ?? this.purchasePending,
      products: products ?? this.products,
      notFoundIds: notFoundIds ?? this.notFoundIds,
      storeMessage: identical(storeMessage, _sentinel)
          ? this.storeMessage
          : storeMessage as String?,
    );
  }

  static const Object _sentinel = Object();
}

class SubscriptionRepository {
  static const _boxName = 'wonderlens_subscription';
  static const _kActive = 'plus_active';
  static const _kProductId = 'product_id';
  static const _kActivatedAt = 'activated_at';
  static const _kSource = 'source';

  /// Override bằng dart-define khi App Store Connect / Play Console đã tạo sản phẩm:
  /// `--dart-define=WONDERLENS_PLUS_YEARLY_ID=com.wonderlens.plus.yearly`
  /// `--dart-define=WONDERLENS_PLUS_MONTHLY_ID=com.wonderlens.plus.monthly`
  static const yearlyProductId = String.fromEnvironment(
    'WONDERLENS_PLUS_YEARLY_ID',
    defaultValue: 'wonderlens_plus_yearly',
  );
  static const monthlyProductId = String.fromEnvironment(
    'WONDERLENS_PLUS_MONTHLY_ID',
    defaultValue: 'wonderlens_plus_monthly',
  );

  static Box? _box;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  static final InAppPurchase _iap = InAppPurchase.instance;
  static final Map<String, ProductDetails> _storeProducts =
      <String, ProductDetails>{};

  static Set<String> get productIds => <String>{
    yearlyProductId,
    monthlyProductId,
  }.where((id) => id.trim().isNotEmpty).toSet();

  static final ValueNotifier<SubscriptionState> state =
      ValueNotifier<SubscriptionState>(const SubscriptionState.inactive());

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    _hydrate();
    _listenToPurchases();
    await refreshProducts();
  }

  @visibleForTesting
  static void debugSetBox(Box? box) {
    _box = box;
    _storeProducts.clear();
    _hydrate();
  }

  bool get isPremium => state.value.isPremium;

  static Future<void> refreshProducts() async {
    if (productIds.isEmpty) return;
    state.value = state.value.copyWith(loadingStore: true, storeMessage: null);
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        state.value = state.value.copyWith(
          storeAvailable: false,
          loadingStore: false,
          storeMessage: 'Store chưa sẵn sàng trên thiết bị này.',
        );
        return;
      }

      final response = await _iap.queryProductDetails(productIds);
      _storeProducts
        ..clear()
        ..addEntries(response.productDetails.map((p) => MapEntry(p.id, p)));

      state.value = state.value.copyWith(
        storeAvailable: true,
        loadingStore: false,
        products: <String, StoreProductSnapshot>{
          for (final p in response.productDetails)
            p.id: StoreProductSnapshot(
              id: p.id,
              title: p.title,
              description: p.description,
              price: p.price,
            ),
        },
        notFoundIds: response.notFoundIDs.toSet(),
        storeMessage: response.error?.message,
      );
    } catch (e) {
      state.value = state.value.copyWith(
        storeAvailable: false,
        loadingStore: false,
        storeMessage: 'Chưa kết nối được Store: $e',
      );
    }
  }

  Future<SubscriptionPurchaseResult> purchasePlan(String productId) async {
    final product = _storeProducts[productId];
    if (product == null) {
      await activateMock(productId);
      return SubscriptionPurchaseResult.mockActivated;
    }

    state.value = state.value.copyWith(
      purchasePending: true,
      storeMessage: null,
    );
    try {
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        state.value = state.value.copyWith(
          purchasePending: false,
          storeMessage: 'Store chưa mở được giao dịch.',
        );
        return SubscriptionPurchaseResult.unavailable;
      }
      return SubscriptionPurchaseResult.storeStarted;
    } catch (e) {
      state.value = state.value.copyWith(
        purchasePending: false,
        storeMessage: 'Không thể bắt đầu giao dịch: $e',
      );
      return SubscriptionPurchaseResult.unavailable;
    }
  }

  Future<void> activateMock(String productId) =>
      _activate(productId: productId, source: 'mock');

  Future<bool> restore() async {
    _hydrate();
    if (state.value.storeAvailable || _storeProducts.isNotEmpty) {
      state.value = state.value.copyWith(purchasePending: true);
      try {
        await _iap.restorePurchases();
      } catch (e) {
        state.value = state.value.copyWith(
          purchasePending: false,
          storeMessage: 'Không khôi phục được từ Store: $e',
        );
      }
    }
    return state.value.isPremium;
  }

  static void _listenToPurchases() {
    _purchaseSub ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        state.value = state.value.copyWith(
          purchasePending: false,
          storeMessage: 'Store báo lỗi: $error',
        );
      },
    );
  }

  static Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        state.value = state.value.copyWith(purchasePending: true);
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        state.value = state.value.copyWith(
          purchasePending: false,
          storeMessage: purchase.error?.message ?? 'Store báo lỗi giao dịch.',
        );
      }

      final validProduct = productIds.contains(purchase.productID);
      final bought = purchase.status == PurchaseStatus.purchased;
      final restored = purchase.status == PurchaseStatus.restored;
      if ((bought || restored) && validProduct) {
        await _activate(productId: purchase.productID, source: 'store');
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }

    state.value = state.value.copyWith(purchasePending: false);
  }

  static Future<void> _activate({
    required String productId,
    required String source,
  }) async {
    final box = _box;
    final now = vnNow();
    if (box != null) {
      await box.put(_kActive, true);
      await box.put(_kProductId, productId);
      await box.put(_kActivatedAt, now.toIso8601String());
      await box.put(_kSource, source);
    }
    state.value = state.value.copyWith(
      isPremium: true,
      productId: productId,
      activatedAt: now,
      source: source,
      purchasePending: false,
      storeMessage: null,
    );
  }

  static void _hydrate() {
    final previous = state.value;
    final box = _box;
    if (box == null || ((box.get(_kActive) as bool?) ?? false) == false) {
      state.value = SubscriptionState(
        isPremium: false,
        storeAvailable: previous.storeAvailable,
        loadingStore: previous.loadingStore,
        purchasePending: previous.purchasePending,
        products: previous.products,
        notFoundIds: previous.notFoundIds,
        storeMessage: previous.storeMessage,
      );
      return;
    }
    final rawDate = box.get(_kActivatedAt) as String?;
    state.value = previous.copyWith(
      isPremium: true,
      productId: box.get(_kProductId) as String?,
      activatedAt: rawDate == null ? null : DateTime.tryParse(rawDate),
      source: (box.get(_kSource) as String?) ?? 'local',
    );
  }
}
