import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_advisor_mobile/core/services/notification_navigation_service.dart';
import 'package:travel_advisor_mobile/core/services/notification_service.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/cubit/profile_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'tab_cubit.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/features/home/presentation/screens/explore_screen.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_cubit.dart';
import 'package:travel_advisor_mobile/features/home/presentation/widgets/notification_drawer.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_screen.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_state.dart';
import 'package:travel_advisor_mobile/features/saved/presentation/cubit/saved_cubit.dart';
import 'package:travel_advisor_mobile/features/saved/presentation/screens/saved_screen.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/screens/trip_planner_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class MainShellTabController {
  static void Function(int index)? _selectTab;

  static bool selectTab(int index) {
    final selectTab = _selectTab;
    if (selectTab == null) return false;
    selectTab(index);
    return true;
  }
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  RealtimeChannel? _notificationChannel;
  StreamSubscription? _fcmSubscription;
  late final SavedCubit _savedCubit = sl<SavedCubit>();
  late final NotificationCubit _notificationCubit = sl<NotificationCubit>()
    ..loadNotifications();

  late final List<Widget> _pages = [
    const ExploreScreen(),
    const ItineraryScreen(),
    const SizedBox.shrink(),
    BlocProvider.value(value: _savedCubit, child: const SavedScreen()),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initNotifications();
      // Người dùng bấm link chia sẻ lịch trình khi chưa đăng nhập:
      // đăng nhập xong (vào MainShell) mới hiện lời mời tham gia.
      NotificationNavigationService.processPendingItineraryShareLink();
    });
  }

  Future<void> _initNotifications() async {
    await NotificationService().init();
    if (!mounted) return;
    await _requestNotificationPermissionWithReason();
  }

  Future<void> _requestNotificationPermissionWithReason() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return;

    final allow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cho phép nhận thông báo?'),
        content: const Text(
          'Ứng dụng dùng thông báo để báo khi bạn check-in địa điểm trong lịch trình, '
          'nhắc mở đúng ngày lịch trình và gợi ý đặt món khi bạn gần quán ăn. '
          'Bạn có thể tắt quyền này bất cứ lúc nào trong Cài đặt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Để sau'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cho phép'),
          ),
        ],
      ),
    );
    if (allow != true) return;

    final granted = await NotificationService().requestPermission();
    if (!mounted || granted) return;

    final after = await Permission.notification.status;
    if (after.isPermanentlyDenied) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thông báo đang bị tắt'),
          content: const Text(
            'Bạn đã tắt quyền thông báo cho ứng dụng. Mở Cài đặt để bật lại nếu muốn nhận nhắc check-in và đặt món.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Mở Cài đặt'),
            ),
          ],
        ),
      );
    }
  }

  void _listenToNotifications(String touristId) {
    if (_notificationChannel != null) return;

    _notificationChannel = Supabase.instance.client
        .channel('public:users_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'users_notifications',
          callback: (payload) async {
            final newRow = payload.newRecord;

            if (newRow['user_id'] != touristId) return;

            if (newRow['notification_id'] != null) {
              if (mounted) {
                _notificationCubit.loadNotifications(silent: true);
              }
              try {
                final notificationResponse = await Supabase.instance.client
                    .from('notifications')
                    .select(
                      'title, content, type, action_type, target_type, metadata',
                    )
                    .eq('id', newRow['notification_id'])
                    .single();
                final metadata = notificationResponse['metadata'];
                final payload = <String, dynamic>{
                  if (metadata is Map) ...Map<String, dynamic>.from(metadata),
                  if (notificationResponse['action_type'] != null)
                    'action': notificationResponse['action_type'].toString(),
                  if (notificationResponse['type'] != null)
                    'type': notificationResponse['type'].toString(),
                  'notification_id': newRow['notification_id'].toString(),
                };

                if (mounted) {
                  NotificationService().showNotification(
                    title: notificationResponse['title'] ?? 'Thông báo',
                    body: notificationResponse['content'] ?? '',
                    payload: jsonEncode(payload),
                  );
                }
              } catch (e) {
                // Fallback nếu không lấy được nội dung chi tiết
                if (mounted) {
                  NotificationService().showNotification(
                    title: 'Thông báo mới',
                    body: 'Bạn có một cập nhật mới về đánh giá!',
                  );
                }
              }
            }
          },
        )
        .subscribe();

    // Thêm listener cho FCM để cập nhật tức thì nếu realtime của Supabase bị trễ
    _fcmSubscription ??= FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        _notificationCubit.loadNotifications(silent: true);
      }
    });
  }

  @override
  void dispose() {
    MainShellTabController._selectTab = null;
    _fcmSubscription?.cancel();
    if (_notificationChannel != null) {
      Supabase.instance.client.removeChannel(_notificationChannel!);
    }
    _savedCubit.close();
    _notificationCubit.close();
    super.dispose();
  }

  void _handleBottomNavTap(BuildContext navigationContext, int i) {
    if (i == 2) {
      Navigator.of(navigationContext).push(
        MaterialPageRoute(
          builder: (context) => const TripPlannerScreen(),
        ),
      );
      return;
    }
    if (i == 1) {
      final cubit = navigationContext.read<ItineraryCubit>();
      if (cubit.state is ItineraryInitial) cubit.loadData();
    }
    if (i == 4) {
      final cubit = navigationContext.read<ProfileCubit>();
      if (cubit.state is ProfileInitial) cubit.loadProfile();
    }
    if (i == 3) {
      _savedCubit.loadSavedContent(silent: true);
    }
    navigationContext.read<TabCubit>().changeTab(i);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ItineraryCubit>()),
        BlocProvider(create: (_) => sl<ProfileCubit>()),
        BlocProvider(create: (_) => sl<TrackingCubit>()),
        BlocProvider(create: (_) => TabCubit()),
        BlocProvider.value(value: _notificationCubit),
      ],
      child: _TrackingRestorer(
        child: BlocBuilder<TabCubit, int>(
          builder: (context, currentIndex) {
            MainShellTabController._selectTab = (i) =>
                _handleBottomNavTap(context, i);
            // Bắt trường hợp Profile đã load xong trước khi Widget build (ví dụ Hot Reload)
            final currentState = context.read<ProfileCubit>().state;
            if (currentState is ProfileLoaded && _notificationChannel == null) {
              _listenToNotifications(currentState.profile.id);
            }

            return BlocListener<ProfileCubit, ProfileState>(
              listener: (context, profileState) {
                if (profileState is ProfileLoaded &&
                    _notificationChannel == null) {
                  _listenToNotifications(profileState.profile.id);
                }
              },
              child: Scaffold(
                key: _scaffoldKey,
                drawer: const ProfileDrawer(),
                endDrawer: const NotificationDrawer(),
                body: IndexedStack(index: currentIndex, children: _pages),
                bottomNavigationBar: SharedBottomNav(
                  currentIndex: currentIndex,
                  onTap: (i) => _handleBottomNavTap(context, i),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Widget đặt bên trong MultiBlocProvider để gọi restoreIfActive() từ đúng
/// descendant context — tránh lỗi ProviderNotFoundException khi gọi từ
/// ancestor context trong initState() của _MainShellState.
class _TrackingRestorer extends StatefulWidget {
  final Widget child;
  const _TrackingRestorer({required this.child});

  @override
  State<_TrackingRestorer> createState() => _TrackingRestorerState();
}

class _TrackingRestorerState extends State<_TrackingRestorer> {
  String? _syncedActiveItineraryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TrackingCubit>().restoreIfActive();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TrackingCubit, TrackingState>(
      listenWhen: (previous, current) =>
          current.isActive &&
          current.itineraryId != null &&
          current.itineraryId != _syncedActiveItineraryId,
      listener: (context, state) {
        final itineraryId = state.itineraryId;
        if (itineraryId == null || itineraryId.isEmpty) return;
        _syncedActiveItineraryId = itineraryId;
        context.read<ItineraryCubit>().toggleItineraryStatus(itineraryId, true);
      },
      child: widget.child,
    );
  }
}

// ─── Notch Painter ────────────────────────────────────────────────────────────
/// Paints a white bar with a smooth U-shaped notch at the top-centre.
///
/// Geometry:
///   - The notch circle is centred at (cx, 0) — the bar's top edge.
///   - It intersects the top edge at (cx−R, 0) and (cx+R, 0).
///   - `arcToPoint` with clockwise:false traces the arc DOWNWARD through
///     (cx, R), producing the U-shaped cutout into the bar.
///   - Cubic bezier blends on each side give G1-continuous transitions
///     from the horizontal top edge to the vertical arc tangent.
class _NotchPainter extends CustomPainter {
  final Color color;
  final double notchRadius;

  const _NotchPainter({required this.color, required this.notchRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double nr = notchRadius;
    // Bezier blend width — wider = smoother shoulder transition
    const double blend = 14.0;

    // ── Build bar path with U-notch ──────────────────────────────────────────
    //
    //  top edge:  0────────(cx-nr)╮          ╭(cx+nr)────────── width
    //                              ╰──(cx,nr)─╯   ← notch dips into bar
    //
    // The arc goes from (cx-nr, 0) counterclockwise (clockwise:false)
    // to (cx+nr, 0), sweeping through the bottom (cx, nr) of the circle.
    //
    // Bezier control points at negative-y pull the exit/entry tangent
    // to be vertical (downward), giving G1 continuity at the junctions.
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(cx - nr - blend, 0)
      // Left blend: horizontal → vertical downward at arc entry
      ..cubicTo(
        cx - nr - blend * 0.55,
        0, // control 1 — stay flat
        cx - nr,
        -blend * 0.3, // control 2 — above bar → exits DOWN at P3
        cx - nr,
        0, // P3 = arc entry (tangent = DOWN ✓)
      )
      // U-shaped notch arc (clockwise:false = counterclockwise in Flutter
      // screen coords = sweeps DOWNWARD from left tangent to right tangent)
      ..arcToPoint(
        Offset(cx + nr, 0),
        radius: Radius.circular(nr),
        clockwise: false,
      )
      // Right blend: vertical upward → horizontal (mirror of left)
      ..cubicTo(
        cx + nr,
        -blend * 0.3, // control 1 — above bar → enters from UP ✓
        cx + nr + blend * 0.55,
        0, // control 2 — flatten back out
        cx + nr + blend,
        0, // P3 = back to flat top edge
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Top shadow (blur extends above bar, creating a subtle top-edge shadow)
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Bar fill (covers the shadow inside the bar)
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _NotchPainter old) =>
      old.color != color || old.notchRadius != notchRadius;
}

// ─── SharedBottomNav ────────────────────────────────────────────────────────
class SharedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SharedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // ── Dimensions ────────────────────────────────────────────────────────────
  /// Height of the white bar
  static const double _barHeight = 64.0;

  /// FAB diameter (must be ≤ 2 × _notchRadius - 2 × _notchMargin to fit)
  static const double _fabDiameter = 56.0;
  static const double _fabRadius = _fabDiameter / 2; // 28

  /// Gap between FAB edge and notch edge
  static const double _notchMargin = 6.0;

  /// Notch circle radius = FAB radius + margin
  static const double _notchRadius = _fabRadius + _notchMargin; // 34

  /// Must match painter blend width
  static const double _blend = 14.0;

  /// Width of the centre column in the Row (covers the full notch + blend)
  static const double _centerColWidth = (_notchRadius + _blend) * 2; // 96

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double totalHeight = _barHeight + bottomInset;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ── Notched white bar ───────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: totalHeight,
            child: CustomPaint(
              painter: const _NotchPainter(
                color: Colors.white,
                notchRadius: _notchRadius,
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Left 2 nav items ───────────────────────────────
                    Expanded(
                      child: _NavItem(
                        icon: Icons.explore_outlined,
                        activeIcon: Icons.explore,
                        label: 'Khám phá',
                        index: 0,
                        current: currentIndex,
                        onTap: onTap,
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.map_outlined,
                        activeIcon: Icons.map,
                        label: 'Lịch trình',
                        index: 1,
                        current: currentIndex,
                        onTap: onTap,
                      ),
                    ),

                    // ── Centre gap: notch + label ──────────────────────
                    SizedBox(
                      width: _centerColWidth,
                      child: _CenterNavLabel(onTap: () => onTap(2)),
                    ),

                    // ── Right 2 nav items ──────────────────────────────
                    Expanded(
                      child: _NavItem(
                        icon: Icons.favorite_outline,
                        activeIcon: Icons.favorite,
                        label: 'Đã lưu',
                        index: 3,
                        current: currentIndex,
                        onTap: onTap,
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Cá nhân',
                        index: 4,
                        current: currentIndex,
                        onTap: onTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Floating centre FAB ─────────────────────────────────────
          Positioned(
            top: -_fabRadius,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: _fabDiameter,
                height: _fabDiameter,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.40),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _NavItem ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = current == index;
    final Color itemColor = active
        ? AppColors.primary
        : const Color(0xFFB0B8C1);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              active ? activeIcon : icon,
              key: ValueKey(active),
              color: itemColor,
              size: active ? 24 : 22,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              height: 1.0,
              color: itemColor,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _CenterNavLabel ─────────────────────────────────────────────────────────
/// The label under the centre FAB.
/// - Inactive gray by default (matches other inactive items).
/// - Turns primary blue while the button is physically pressed.
/// - Vertically aligned with other labels using a phantom icon SizedBox.
class _CenterNavLabel extends StatefulWidget {
  final VoidCallback onTap;
  const _CenterNavLabel({required this.onTap});

  @override
  State<_CenterNavLabel> createState() => _CenterNavLabelState();
}

class _CenterNavLabelState extends State<_CenterNavLabel> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color labelColor = _pressed
        ? AppColors.primary
        : const Color(0xFFB0B8C1);

    return GestureDetector(
      onTap: widget.onTap,
      // Show blue on press-down, revert on release / cancel
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phantom icon space — matches icon(22) + gap(3) in _NavItem
          // so the label sits at the exact same baseline as other labels.
          const SizedBox(height: 22 + 3),
          Text(
            'T\u1ea1o l\u1ecbch tr\u00ecnh',
            style: TextStyle(
              fontSize: 10,
              height: 1.0,
              color: labelColor,
              fontWeight: _pressed ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Keep old public alias so external usages (e.g. city_detail_screen) still compile.
// ignore: camel_case_types
typedef NavItem = _NavItem;
