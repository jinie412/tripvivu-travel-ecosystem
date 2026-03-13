import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/home/presentation/screens/explore_screen.dart';
import '../../features/itinerary/presentation/screens/itinerary_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection_container.dart';

/// Shell chính chứa Bottom Navigation Bar + IndexedStack các tab.
///
/// 5 tab: Khám phá (0) · Lịch trình (1) · [+] FAB (2) · Đã lưu (3) · Cá nhân (4)
/// Tab 2 không có trang — chỉ có FAB ở giữa.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  /// Danh sách các trang tương ứng với tab navigation.
  /// Index 2 bỏ trống (FAB slot).
  final List<Widget> _pages = [
    const ExploreScreen(),        // 0 — Khám phá
    const ItineraryScreen(),      // 1 — Lịch trình
    const SizedBox.shrink(),      // 2 — placeholder cho FAB
    const _PlaceholderTab(title: 'Đã lưu', icon: Icons.favorite), // 3
    BlocProvider(                 // 4 - Cá nhân
      create: (_) => sl<ProfileCubit>()..loadProfile(),
      child: const ProfileScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          // Bỏ qua tap vào slot FAB (index 2).
          if (i == 2) return;
          setState(() => _currentIndex = i);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Mở màn tạo lịch trình mới.
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ── Bottom Navigation Bar ────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
              label: 'Khám phá',
              index: 0,
              current: currentIndex,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map,
              label: 'Lịch trình',
              index: 1,
              current: currentIndex,
              onTap: onTap,
            ),
            // Khoảng trống cho FAB notch.
            const SizedBox(width: 56),
            _NavItem(
              icon: Icons.favorite_outline,
              activeIcon: Icons.favorite,
              label: 'Đã lưu',
              index: 3,
              current: currentIndex,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Cá nhân',
              index: 4,
              current: currentIndex,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

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

// ═══════════════════════════════════════════════════════════════════════════════
// ── Placeholder cho tab chưa triển khai ──────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: const Color(0xFFBDBDBD)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tính năng đang phát triển',
              style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      ),
    );
  }
}
