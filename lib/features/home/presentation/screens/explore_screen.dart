import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/page_dots.dart';
import '../../../../core/widgets/section_header.dart';
import '../cubit/explore_cubit.dart';
import '../cubit/explore_state.dart';
import '../widgets/current_itinerary_card.dart';
import '../widgets/destination_card.dart';
import '../widgets/explore_header.dart';
import '../widgets/hotel_card.dart';
import '../widgets/trip_card_widget.dart';

import '../../../profile/presentation/widgets/profile_drawer.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExploreCubit>()..loadData(),
      child: const _ExploreView(),
    );
  }
}

class _ExploreView extends StatefulWidget {
  const _ExploreView();

  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView> {
  int _suggestionPage = 0;
  int _destPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const ProfileDrawer(),
      body: BlocBuilder<ExploreCubit, ExploreState>(
        builder: (context, state) {
          if (state is ExploreLoading || state is ExploreInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExploreError) {
            return ErrorView(
              error: state.message,
              onRetry: () => context.read<ExploreCubit>().loadData(),
            );
          }
          if (state is ExploreLoaded) {
            return Column(
              children: [
                const ExploreHeader(),
                Expanded(child: _buildContent(context, state)),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExploreLoaded state) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              SectionHeader(title: 'Lịch trình của bạn', onSeeAll: () {}),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CurrentItineraryCard(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        // ── Gợi ý cho bạn ────────────────────────────────────────────────
        if (state.suggestions.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Gợi ý cho bạn', onSeeAll: () {}),
                const SizedBox(height: 12),
                SizedBox(
                  height: 230,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.88),
                    padEnds: false,
                    clipBehavior: Clip.none,
                    itemCount: state.suggestions.length,
                    onPageChanged: (i) => setState(() => _suggestionPage = i),
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 16 : 0,
                        right: 12,
                      ),
                      child: TripCardWidget(item: state.suggestions[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                PageDots(count: state.suggestions.length, current: _suggestionPage),
              ],
            ),
          ),
        // ── Điểm đến nổi bật ─────────────────────────────────────────────
        if (state.destinations.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                SectionHeader(title: 'Điểm đến nổi bật', onSeeAll: () {}),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.31),
                    padEnds: false,
                    clipBehavior: Clip.none,
                    itemCount: state.destinations.length,
                    onPageChanged: (i) => setState(() => _destPage = i),
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 16 : 0,
                        right: 10,
                      ),
                      child: DestinationCard(item: state.destinations[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PageDots(count: state.destinations.length, current: _destPage),
              ],
            ),
          ),
        // ── Khách sạn nổi bật ─────────────────────────────────────────────
        if (state.hotels.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                SectionHeader(title: 'Khách sạn nổi bật', onSeeAll: () {}),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: state.hotels
                        .map((h) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: h == state.hotels.last ? 0 : 12),
                                child: HotelCard(item: h),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}



