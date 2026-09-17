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
    _favoriteSubscription = sl<FavoriteRemoteDataSource>().changes.listen((
      event,
    ) {
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
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
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                    decoration: const BoxDecoration(
                      color: AppColors.premiumSurface,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    // padding: const EdgeInsets.fromLTRB(AppSizes.s16, AppSizes.s12, AppSizes.s16, AppSizes.s12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.premiumSoftBlue,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Builder(
                            builder: (ctx) => IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.menu_rounded,
                                color: AppColors.premiumNavy,
                                size: 20,
                              ),
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
                              color: AppColors.premiumNavy,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 48,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.premiumSoftBlue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TabBar(
                      tabs: const [
                        Tab(text: 'Lịch trình'),
                        Tab(text: 'Địa điểm'),
                      ],
                      labelColor: AppColors.premiumNavy,
                      unselectedLabelColor: AppColors.premiumMuted,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.premiumNavy.withValues(alpha: .08),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      dividerColor: Colors.transparent,
                    ),
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
                                    padding: const EdgeInsets.only(
                                      bottom: AppSizes.s16,
                                    ),
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
                                              builder: (_) =>
                                                  BlocProvider.value(
                                                    value: cubit,
                                                    child:
                                                        ItinerarySummaryScreen(
                                                          itineraryId: item.id,
                                                        ),
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
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    averageRating: favPlace.rating,
                                    reviewCount: favPlace.reviewCount,
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

  const _SavedEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.premiumSoftBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.premiumBlue),
            ),
            const SizedBox(height: AppSizes.s12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.premiumMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
