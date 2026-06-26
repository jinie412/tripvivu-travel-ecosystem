import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/features/search/presentation/cubit/search_cubit.dart';
import 'package:travel_advisor_mobile/features/search/presentation/cubit/search_state.dart';
import 'package:travel_advisor_mobile/features/search/presentation/screens/search_all_screen.dart';
import 'package:travel_advisor_mobile/features/search/presentation/widgets/search_header_widget.dart';
import 'package:travel_advisor_mobile/features/search/presentation/widgets/search_result_widget.dart';
import 'package:travel_advisor_mobile/features/search/presentation/widgets/search_suggestion_widget.dart';

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

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToSearchAll(BuildContext context) {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập từ khóa tìm kiếm'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchAllScreen(query: q),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.s16, AppSizes.s16, AppSizes.s16, 0),
              child: SearchHeaderWidget(
                controller: _searchController,
                onClear: () {
                  _searchController.clear();
                  context.read<SearchCubit>().onSearchQueryChanged('');
                },
                onChanged: (v) =>
                    context.read<SearchCubit>().onSearchQueryChanged(v),
                onSubmitted: (_) => _goToSearchAll(context),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.s16),
                child: BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) => state.when(
                    initial: () =>
                        const Center(child: CircularProgressIndicator()),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    loaded: (recent) =>
                        SearchSuggestionWidget(recentSearches: recent),
                    searching: () =>
                        const Center(child: CircularProgressIndicator()),
                    searchResults: (results) => SearchResultWidget(
                      results: results,
                      onViewAll: () => _goToSearchAll(context),
                    ),
                    multiResults: (_) => const SizedBox.shrink(),
                    error: (msg) => Center(child: Text(msg)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
