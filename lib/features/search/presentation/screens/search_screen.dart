import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import '../widgets/search_header_widget.dart';
import '../widgets/search_suggestion_widget.dart';
import '../widgets/search_result_widget.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchCubit>()..loadRecentSearches(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView();

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white, // Pure white background as requested
      body: SafeArea(
        child: Column(
          children: [
            // Search Header (Top Nav)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SearchHeaderWidget(
                controller: searchController,
                onClear: () {
                  searchController.clear();
                  context.read<SearchCubit>().onSearchQueryChanged('');
                },
                onChanged: (value) => context.read<SearchCubit>().onSearchQueryChanged(value),
              ),
            ),

            // Main Body: Hint + Recent Searches
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) {
                    return state.when(
                      initial: () => const Center(child: CircularProgressIndicator()),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      loaded: (recentSearches) => SearchSuggestionWidget(
                        recentSearches: recentSearches,
                      ),
                      searching: () => const Center(child: CircularProgressIndicator()),
                      searchResults: (results) => SearchResultWidget(
                        results: results,
                      ),
                      error: (message) => Center(child: Text(message)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
