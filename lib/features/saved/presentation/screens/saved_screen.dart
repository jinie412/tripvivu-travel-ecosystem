import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/error_view.dart';
import 'package:travel_advisor_mobile/features/home/presentation/widgets/destination_card.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_summary_screen.dart';
import 'package:travel_advisor_mobile/features/saved/presentation/cubit/saved_cubit.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/saved/presentation/cubit/saved_state.dart';
import 'package:travel_advisor_mobile/features/saved/presentation/widgets/saved_itinerary_card.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  StreamSubscription<FavoriteChangedEvent>? _favoriteSubscription;

  @override
  void initState() {
    super.initState();
    context.read<SavedCubit>().loadSavedContent();
    _favoriteSubscription = sl<FavoriteRemoteDataSource>().changes.listen((event) {
      if (!mounted) return;
      final cubit = context.read<SavedCubit>();
      cubit.applyFavoriteChange(event);
      cubit.loadSavedContent(silent: true);
    });
  }

  @override
  void dispose() {
    _favoriteSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: BlocBuilder<SavedCubit, SavedState>(
          builder: (context, state) {
            if (state is SavedLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (state is SavedError) {
              return ErrorView(
                error: state.message,
                onRetry: () => context.read<SavedCubit>().loadSavedContent(),
              );
            }
            if (state is SavedLoaded) {
              return DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 24,
                        right: 24,
                      ),
                      // padding: const EdgeInsets.fromLTRB(AppSizes.s16, AppSizes.s12, AppSizes.s16, AppSizes.s12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Builder(
                              builder: (ctx) => IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.menu, color: AppColors.primary, size: 20),
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Bộ sưu tập',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const TabBar(
                      tabs: [
                        Tab(text: 'Lịch trình'),
                        Tab(text: 'Địa điểm'),
                      ],
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                      indicatorColor: AppColors.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorWeight: 3,
                      dividerColor: Colors.transparent,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // TAB 1: ITINERARIES
                          state.itineraries.isEmpty
                              ? const _SavedEmptyState(
                                  icon: Icons.map_outlined,
                                  message: 'Bạn chưa lưu lịch trình nào.',
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(AppSizes.s16),
                                  itemCount: state.itineraries.length,
                                  itemBuilder: (context, index) {
                                    final item = state.itineraries[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: AppSizes.s16),
                                      child: SizedBox(
                                        height: 270,
                                        child: SavedItineraryCard(
                                          item: item,
                                          onTap: () {
                                            final cubit = sl<ItineraryCubit>();
                                            cubit.selectItinerary(item.id);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BlocProvider.value(
                                                  value: cubit,
                                                  child: ItinerarySummaryScreen(itineraryId: item.id),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          // TAB 2: PLACES
                          state.places.isEmpty
                              ? const _SavedEmptyState(
                                  icon: Icons.place_outlined,
                                  message: 'Bạn chưa lưu địa điểm nào.',
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: AppSizes.s16,
                                    crossAxisSpacing: AppSizes.s16,
                                    childAspectRatio: 0.82,
                                  ),
                                  itemCount: state.places.length,
                                  itemBuilder: (context, index) {
                                    final favPlace = state.places[index];
                                    final destination = Destination(
                                      id: favPlace.id,
                                      name: favPlace.name,
                                      imageUrl: favPlace.image,
                                    );
                                    return DestinationCard(item: destination);
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
    );
  }
}

class _SavedEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SavedEmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: AppSizes.s12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
