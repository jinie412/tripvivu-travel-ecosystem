import 'package:flutter/material.dart';
import '../../features/home/presentation/widgets/notification_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/di/injection_container.dart';
import '../../features/home/presentation/screens/explore_screen.dart';
import '../../features/itinerary/presentation/screens/itinerary_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/saved/presentation/screens/saved_screen.dart';
import '../../features/saved/presentation/cubit/saved_cubit.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/itinerary/presentation/cubit/itinerary_cubit.dart';
import '../../features/trip_planner/presentation/screens/trip_planner_screen.dart';
import '../../features/profile/presentation/widgets/profile_drawer.dart';
import 'tab_cubit.dart';

/// Shell chính chứa Bottom Navigation Bar + IndexedStack các tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// Danh sách các trang tương ứng với tab navigation.
  final List<Widget> _pages = [
    const ExploreScreen(), // 0 — Khám phá
    const ItineraryScreen(), // 1 — Lịch trình
    const SizedBox.shrink(), // 2 — placeholder cho FAB
    BlocProvider(
      create: (context) => sl<SavedCubit>(),
      child: const SavedScreen(),
    ), // 3 — Đã lưu
    const ProfileScreen(), // 4 - Cá nhân
  ];

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
          return Scaffold(
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
          );
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
      height: 90, 
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
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tạo lịch trình',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.normal,
                    ),
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
            color: active ? AppColors.primary : const Color(0xFF9E9E9E),
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? AppColors.primary : const Color(0xFF9E9E9E),
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
