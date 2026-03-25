import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../home/presentation/widgets/destination_card.dart';
import '../cubit/saved_cubit.dart';
import '../cubit/saved_state.dart';
import '../widgets/saved_itinerary_card.dart';
import '../../../../core/di/injection_container.dart';
import '../../../itinerary/presentation/cubit/itinerary_cubit.dart';
import '../../../itinerary/presentation/screens/itinerary_summary_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SavedCubit>().loadSavedContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                          ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.itineraries.length,
                            itemBuilder: (context, index) {
                              final item = state.itineraries[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
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
                          GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.82,
                            ),
                            itemCount: state.places.length,
                            itemBuilder: (context, index) {
                              return DestinationCard(item: state.places[index]);
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
      ),
    );
  }
}
