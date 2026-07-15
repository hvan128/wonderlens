import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:go_router/go_router.dart';

import '../data/subscription_repository.dart';
import '../ui/ui.dart';
import '../widgets/legal_links.dart';

String _platformStoreName() => switch (defaultTargetPlatform) {
  TargetPlatform.iOS => 'App Store',
  TargetPlatform.android => 'Google Play',
  _ => 'Store',
};

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const _annual = _Plan(
    id: SubscriptionRepository.yearlyProductId,
    title: 'Dùng thử miễn phí',
    price: '3 ngày',
    detail: 'sau đó 499.000đ/năm',
    trial: true,
  );

  static const _monthly = _Plan(
    id: SubscriptionRepository.monthlyProductId,
    title: 'Gói tháng',
    price: '89.000đ',
    detail: 'mỗi tháng',
    trial: false,
  );

  static const _plans = <_Plan>[_annual, _monthly];

  String _selectedId = _annual.id;
  bool _busy = false;

  _Plan get _selectedPlan =>
      _plans.firstWhere((p) => p.id == _selectedId, orElse: () => _annual);

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _activateSelected() async {
    if (SubscriptionRepository.state.value.isPremium || _busy) return;

    final allowed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ParentGateDialog(),
    );
    if (allowed != true || !mounted) return;

    setState(() => _busy = true);
    final result = await SubscriptionRepository().purchasePlan(
      _selectedPlan.id,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case SubscriptionPurchaseResult.mockActivated:
        WonderHaptics.success();
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Bạn đã sẵn sàng', style: WonderType.heading),
            content: Text(
              'WonderLens Plus đã bật trên thiết bị này.',
              style: WonderType.body.copyWith(color: WonderColors.textSoft),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: WonderType.textButton),
              ),
            ],
          ),
        );
      case SubscriptionPurchaseResult.storeStarted:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hoàn tất giao dịch trong cửa sổ ${_platformStoreName()}.',
            ),
          ),
        );
      case SubscriptionPurchaseResult.unavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              SubscriptionRepository.state.value.storeMessage ??
                  'Store chưa sẵn sàng. Vui lòng thử lại sau.',
            ),
          ),
        );
    }
  }

  Future<void> _restore() async {
    final restored = await SubscriptionRepository().restore();
    if (!mounted) return;
    final current = SubscriptionRepository.state.value;
    final message = restored
        ? 'Đã khôi phục WonderLens Plus trên thiết bị này.'
        : (current.storeAvailable
              ? 'Đang kiểm tra giao dịch từ ${_platformStoreName()}. Nếu có, Plus sẽ tự bật.'
              : 'Chưa tìm thấy giao dịch Plus trên thiết bị này.');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _storeNote(SubscriptionState state) {
    final storeName = _platformStoreName();
    if (state.loadingStore) {
      return 'Đang kết nối $storeName để lấy giá và gói thật.';
    }
    if (state.products.isNotEmpty) {
      return 'Thanh toán và gia hạn được quản lý bởi $storeName.';
    }
    return 'Chưa thấy product IDs trên $storeName, nên nút dùng fallback nội bộ và chưa thu tiền thật.';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WonderBackground(
        child: ValueListenableBuilder<SubscriptionState>(
          valueListenable: SubscriptionRepository.state,
          builder: (context, state, _) {
            final premium = state.isPremium;
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      WonderTokens.space16,
                      WonderTokens.space8,
                      WonderTokens.space16,
                      150 + bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _TopBar(onClose: _close),
                            const SizedBox(height: WonderTokens.space8),
                            const _HeroCopy(),
                            const SizedBox(height: WonderTokens.space16),
                            _PlanPicker(
                              plans: _plans,
                              selectedId: _selectedId,
                              state: state,
                              onSelect: (id) =>
                                  setState(() => _selectedId = id),
                            ),
                            const SizedBox(height: WonderTokens.space16),
                            const _BenefitList(),
                            const SizedBox(height: WonderTokens.space24),
                            _LegalActions(
                              onRestore: _restore,
                              storeName: _platformStoreName(),
                              storeMessage:
                                  (state.loadingStore || state.products.isEmpty)
                                  ? _storeNote(state)
                                  : null,
                            ),
                            const SizedBox(height: WonderTokens.space16),
                            const LegalLinks(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomCta(
                    premium: premium,
                    busy: _busy || state.purchasePending,
                    plan: _selectedPlan,
                    state: state,
                    bottomInset: bottom,
                    onTap: premium ? _close : _activateSelected,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;

  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Row(
        children: <Widget>[
          const Expanded(child: SizedBox()),
          Pressable(
            onTap: onClose,
            semanticLabel: 'Đóng',
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WonderTokens.space4,
                vertical: WonderTokens.space12,
              ),
              child: Text(
                'Đóng',
                style: WonderType.textButton.copyWith(
                  color: WonderColors.textSoft.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const WonderLogo(size: 72, spin: false),
        const SizedBox(height: WonderTokens.space12),
        Text(
          'Nâng cấp WonderLens Plus',
          textAlign: TextAlign.center,
          style: WonderType.display.copyWith(
            color: WonderColors.textStrong,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: WonderTokens.space8),
        Text(
          'Soi vật nhiều hơn, nghe kể bằng tiếng Việt và lưu lại hành trình khám phá của bé.',
          textAlign: TextAlign.center,
          style: WonderType.body.copyWith(
            color: WonderColors.textSoft,
            fontWeight: FontWeight.w600,
            height: 1.34,
          ),
        ),
      ],
    );
  }
}

class _PlanPicker extends StatelessWidget {
  final List<_Plan> plans;
  final String selectedId;
  final SubscriptionState state;
  final ValueChanged<String> onSelect;

  const _PlanPicker({
    required this.plans,
    required this.selectedId,
    required this.state,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 430;
        Widget cardFor(_Plan plan) => _PlanCard(
          plan: plan,
          selected: plan.id == selectedId,
          storeProduct: state.products[plan.id],
          onTap: () => onSelect(plan.id),
        );
        if (compact) {
          return Column(
            children: <Widget>[
              for (final plan in plans) ...<Widget>[
                cardFor(plan),
                const SizedBox(height: WonderTokens.space12),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: cardFor(plans.first)),
            const SizedBox(width: WonderTokens.space16),
            Expanded(child: cardFor(plans.last)),
          ],
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool selected;
  final StoreProductSnapshot? storeProduct;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.storeProduct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = plan.trial ? WonderColors.sunnyDeep : WonderColors.tealDeep;
    final note = plan.displayNote(storeProduct);
    final borderColor = selected
        ? accent
        : Colors.white.withValues(alpha: 0.86);
    final muted = !selected && !plan.trial;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Chọn ${plan.title}',
      child: AnimatedContainer(
        duration: WonderTokens.durBase,
        curve: WonderTokens.curveStandard,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(WonderTokens.radiusLg),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
          boxShadow: selected
              ? WonderShadows.glow(accent, opacity: 0.18)
              : WonderShadows.card,
        ),
        child: GlassSurface(
          tone: GlassTone.light,
          blur: 8,
          tintOpacity: selected ? 0.46 : 0.30,
          radius: WonderTokens.radiusLg,
          padding: EdgeInsets.zero,
          shadows: const <BoxShadow>[],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (plan.trial)
                AnimatedContainer(
                  duration: WonderTokens.durBase,
                  height: WonderTokens.space40,
                  color: WonderColors.sunny.withValues(
                    alpha: selected ? 0.98 : 0.74,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const PhosphorIcon(
                        PhosphorIconsFill.medal,
                        color: WonderColors.textStrong,
                        size: 18,
                      ),
                      const SizedBox(width: WonderTokens.space8),
                      Text(
                        'Giá tốt nhất',
                        style: WonderType.heading.copyWith(
                          color: WonderColors.textStrong,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: WonderTokens.space8),
                      const PhosphorIcon(
                        PhosphorIconsFill.medal,
                        color: WonderColors.textStrong,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(WonderTokens.space16),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _RadioMark(selected: selected, color: accent),
                        const SizedBox(width: WonderTokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                plan.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: WonderType.heading.copyWith(
                                  color: muted
                                      ? WonderColors.textSoft.withValues(
                                          alpha: 0.58,
                                        )
                                      : WonderColors.textStrong,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: WonderTokens.space4),
                              Text(
                                plan.supportingLine(storeProduct),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: WonderType.caption.copyWith(
                                  color: WonderColors.textSoft.withValues(
                                    alpha: muted ? 0.56 : 0.86,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: WonderTokens.space12),
                        SizedBox(
                          width: 96,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              plan.priceLine(storeProduct),
                              textAlign: TextAlign.right,
                              style: WonderType.heading.copyWith(
                                color: muted
                                    ? WonderColors.textSoft.withValues(
                                        alpha: 0.58,
                                      )
                                    : WonderColors.textStrong,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (note != null) ...<Widget>[
                      const SizedBox(height: WonderTokens.space12),
                      Row(
                        children: <Widget>[
                          const PhosphorIcon(
                            PhosphorIconsFill.warningCircle,
                            color: WonderColors.coral,
                            size: 18,
                          ),
                          const SizedBox(width: WonderTokens.space8),
                          Expanded(
                            child: Text(
                              note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: WonderType.caption.copyWith(
                                color: WonderColors.textSoft,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  final bool selected;
  final Color color;

  const _RadioMark({required this.selected, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: WonderTokens.durBase,
      width: WonderTokens.space32,
      height: WonderTokens.space32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? color
              : WonderColors.textSoft.withValues(alpha: 0.22),
          width: 3,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: WonderTokens.durBase,
          width: selected ? WonderTokens.space16 : 0,
          height: selected ? WonderTokens.space16 : 0,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _BenefitList extends StatelessWidget {
  const _BenefitList();

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      'Dùng thử miễn phí 3 ngày',
      'Huỷ bất cứ lúc nào trong cài đặt ${_platformStoreName()}',
      'Soi vật với AI không giới hạn',
      'Giọng kể tiếng Việt cho bé',
      'Rương khám phá lưu trên thiết bị',
    ];

    return GlassSurface(
      tone: GlassTone.light,
      blur: 8,
      tintOpacity: 0.34,
      radius: WonderTokens.radiusLg,
      padding: const EdgeInsets.all(WonderTokens.space16),
      shadows: WonderShadows.card,
      child: Column(
        children: <Widget>[
          for (final item in items) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const PhosphorIcon(
                  PhosphorIconsBold.check,
                  color: WonderColors.tealDeep,
                  size: 21,
                ),
                const SizedBox(width: WonderTokens.space12),
                Expanded(
                  child: Text(
                    item,
                    style: WonderType.body.copyWith(
                      color: WonderColors.textStrong,
                      fontWeight: FontWeight.w700,
                      height: 1.30,
                    ),
                  ),
                ),
              ],
            ),
            if (item != items.last)
              const SizedBox(height: WonderTokens.space12),
          ],
        ],
      ),
    );
  }
}

class _LegalActions extends StatelessWidget {
  final VoidCallback onRestore;
  final String storeName;
  final String? storeMessage;

  const _LegalActions({
    required this.onRestore,
    required this.storeName,
    required this.storeMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        WonderTextButton(
          label: 'Khôi phục mua hàng',
          onTap: onRestore,
          color: WonderColors.textSoft,
        ),
        Text(
          'Gói gia hạn tự động được quản lý trong $storeName.',
          textAlign: TextAlign.center,
          style: WonderType.caption.copyWith(
            color: WonderColors.textSoft.withValues(alpha: 0.86),
            fontWeight: FontWeight.w700,
            height: 1.28,
          ),
        ),
        if (storeMessage != null) ...<Widget>[
          const SizedBox(height: WonderTokens.space8),
          Text(
            storeMessage!,
            textAlign: TextAlign.center,
            style: WonderType.caption.copyWith(
              color: WonderColors.textSoft.withValues(alpha: 0.80),
              fontWeight: FontWeight.w700,
              height: 1.28,
            ),
          ),
        ],
      ],
    );
  }
}

class _BottomCta extends StatelessWidget {
  final bool premium;
  final bool busy;
  final _Plan plan;
  final SubscriptionState state;
  final double bottomInset;
  final VoidCallback onTap;

  const _BottomCta({
    required this.premium,
    required this.busy,
    required this.plan,
    required this.state,
    required this.bottomInset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final product = state.products[plan.id];
    final label = premium
        ? 'Tiếp tục khám phá'
        : (plan.trial ? 'Bắt đầu dùng thử 3 ngày' : 'Tiếp tục với gói tháng');
    final busyLabel = state.purchasePending
        ? 'Đang chờ Store...'
        : 'Đang bật Plus...';
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(WonderTokens.radiusLg),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: WonderColors.paper.withValues(alpha: 0.86),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.82)),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: WonderColors.tealDeep.withValues(alpha: 0.10),
              blurRadius: 28,
              offset: const Offset(0, -12),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              WonderTokens.space16,
              WonderTokens.space12,
              WonderTokens.space16,
              WonderTokens.space12 + bottomInset * 0.2,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    WonderButton(
                      label: busy ? busyLabel : label,
                      icon: premium
                          ? PhosphorIconsFill.checkCircle
                          : PhosphorIconsFill.sparkle,
                      onTap: busy ? null : onTap,
                      gradient: WonderGradients.cta,
                      glowColor: WonderColors.teal,
                    ),
                    const SizedBox(height: WonderTokens.space8),
                    Text(
                      premium
                          ? (state.source == 'store'
                                ? 'Plus đang hoạt động qua ${_platformStoreName()}'
                                : 'Plus đang hoạt động trên thiết bị này')
                          : plan.ctaCaption(product),
                      textAlign: TextAlign.center,
                      style: WonderType.caption.copyWith(
                        color: WonderColors.textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog();

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final _controller = TextEditingController();
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim() == '12') {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _error = true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WonderTokens.radiusLg),
      ),
      backgroundColor: WonderColors.paper,
      title: Text('Dành cho phụ huynh', style: WonderType.heading),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Để tiếp tục, nhập kết quả: 7 + 5',
            style: WonderType.body.copyWith(color: WonderColors.textSoft),
          ),
          const SizedBox(height: WonderTokens.space12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            style: WonderType.body.copyWith(fontSize: 18),
            decoration: InputDecoration(
              labelText: 'Kết quả',
              errorText: _error ? 'Chưa đúng, thử lại nhé.' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WonderTokens.radiusSm),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WonderTokens.radiusSm),
                borderSide: const BorderSide(
                  color: WonderColors.tealDeep,
                  width: 2,
                ),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Huỷ', style: WonderType.textButton),
        ),
        TextButton(
          onPressed: _submit,
          child: Text('Xác nhận', style: WonderType.textButton),
        ),
      ],
    );
  }
}

class _Plan {
  final String id;
  final String title;
  final String price;
  final String detail;
  final bool trial;

  const _Plan({
    required this.id,
    required this.title,
    required this.price,
    required this.detail,
    required this.trial,
  });

  String displayPrice(StoreProductSnapshot? product) {
    if (trial) return price;
    return product?.price ?? price;
  }

  String displayDetail(StoreProductSnapshot? product) {
    if (trial && product != null) return 'sau đó ${product.price}/năm';
    return detail;
  }

  String supportingLine(StoreProductSnapshot? product) {
    if (trial) {
      return product == null
          ? '3 ngày miễn phí, sau đó 499.000đ/năm'
          : '3 ngày miễn phí, sau đó ${product.price}/năm';
    }
    return 'Gia hạn hằng tháng, huỷ bất cứ lúc nào';
  }

  String priceLine(StoreProductSnapshot? product) {
    if (trial) return product?.price ?? '499.000đ/năm';
    return '${product?.price ?? price}/tháng';
  }

  String? displayNote(StoreProductSnapshot? product) {
    if (product != null) return null;
    return 'Chưa có sản phẩm Store, đang dùng kiểm thử nội bộ.';
  }

  String ctaCaption(StoreProductSnapshot? product) {
    if (trial) {
      return product == null
          ? 'Miễn phí 3 ngày, sau đó 499.000đ/năm'
          : 'Miễn phí 3 ngày, sau đó ${product.price}/năm';
    }
    return '${displayPrice(product)} ${displayDetail(product)}';
  }
}
