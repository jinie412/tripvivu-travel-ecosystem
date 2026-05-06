import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_advisor_mobile/core/services/notification_service.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/cubit/profile_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'tab_cubit.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/home/presentation/screens/explore_screen.dart';
import 'package:travel_advisor_mobile/features/home/presentation/widgets/notification_drawer.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_screen.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/widgets/profile_drawer.dart';
import 'package:travel_advisor_mobile/features/saved/presentation/cubit/saved_cubit.dart';
import 'package:travel_advisor_mobile/features/saved/presentation/screens/saved_screen.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/screens/trip_planner_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  RealtimeChannel? _notificationChannel;

  final List<Widget> _pages = [
    const ExploreScreen(),
    const ItineraryScreen(),
    const SizedBox.shrink(),
    BlocProvider(
      create: (context) => sl<SavedCubit>(),
      child: const SavedScreen(),
    ),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await NotificationService().init();
    await NotificationService().requestPermission();
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
                try {
                  final notificationResponse = await Supabase.instance.client
                      .from('notifications')
                      .select('title, content')
                      .eq('id', newRow['notification_id'])
                      .single();

                  if (mounted) {
                    NotificationService().showNotification(
                      title: notificationResponse['title'] ?? 'Thông báo',
                      body: notificationResponse['content'] ?? '',
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
            })
        .subscribe();
  }

  @override
  void dispose() {
    if (_notificationChannel != null) {
      Supabase.instance.client.removeChannel(_notificationChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ItineraryCubit>()..loadData()),
        BlocProvider(create: (_) => sl<ProfileCubit>()..loadProfile()),
        BlocProvider(create: (_) => TabCubit()),
      ],
      child: BlocBuilder<TabCubit, int>(
        builder: (context, currentIndex) {
          // Bắt trường hợp Profile đã load xong trước khi Widget build (ví dụ Hot Reload)
          final currentState = context.read<ProfileCubit>().state;
          if (currentState is ProfileLoaded && _notificationChannel == null) {
             _listenToNotifications(currentState.profile.id);
          }

          return BlocListener<ProfileCubit, ProfileState>(
            listener: (context, profileState) {
              if (profileState is ProfileLoaded && _notificationChannel == null) {
                _listenToNotifications(profileState.profile.id);
              }
            },
            child: Scaffold(
              key: _scaffoldKey,
              drawer: const ProfileDrawer(),
              endDrawer: const NotificationDrawer(),
              body: IndexedStack(
                index: currentIndex,
                children: _pages,
              ),
              bottomNavigationBar: SharedBottomNav(
                currentIndex: currentIndex,
                onTap: (i) {
                  if (i == 2) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TripPlannerScreen(),
                      ),
                    );
                    return;
                  }
                  context.read<TabCubit>().changeTab(i);
                },
              ),
          ));
        },
      ),
    );
  }
}

class SharedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const SharedBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      padding: EdgeInsets.zero,
      height: AppSizes.bottomNavHeight, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: NavItem(
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
              label: 'Khám phá',
              index: 0,
              current: currentIndex,
              onTap: onTap,
            ),
          ),
          Expanded(
            child: NavItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map,
              label: 'Lịch trình',
              index: 1,
              current: currentIndex,
              onTap: onTap,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(2),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: AppSizes.fabSize,
                    height: AppSizes.fabSize,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: AppSizes.iconDefault),
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    'Tạo lịch trình',
                    style: AppTextStylesExt.captionSmall,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: NavItem(
              icon: Icons.favorite_outline,
              activeIcon: Icons.favorite,
              label: 'Đã lưu',
              index: 3,
              current: currentIndex,
              onTap: onTap,
            ),
          ),
          Expanded(
            child: NavItem(
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
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = current == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            active ? activeIcon : icon,
            color: active ? AppColors.primary : AppColorsExt.textHint,
            size: AppSizes.iconDefault,
          ),
          const SizedBox(height: AppSizes.s2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? AppColors.primary : AppColorsExt.textHint,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}