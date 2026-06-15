import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class PaginatedSeeAllScreen<T> extends StatefulWidget {
  final String title;
  final int pageSize;
  final Future<List<T>> Function(int page, int limit) pageLoader;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;
  // Pre-seeded items from the home state — shown instantly while page 1 loads.
  final List<T> initialItems;

  const PaginatedSeeAllScreen({
    super.key,
    required this.title,
    required this.pageLoader,
    required this.itemBuilder,
    this.pageSize = 10,
    this.emptyMessage = 'Không có dữ liệu để hiển thị.',
    this.initialItems = const [],
  });

  @override
  State<PaginatedSeeAllScreen<T>> createState() => _PaginatedSeeAllScreenState<T>();
}

class _PaginatedSeeAllScreenState<T> extends State<PaginatedSeeAllScreen<T>> {
  final ScrollController _scrollController = ScrollController();
  final List<T> _items = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialItems.isNotEmpty) {
      // Show preloaded items immediately, then refresh page 1 in the background.
      _items.addAll(widget.initialItems);
      _isInitialLoading = false;
      _refreshPage1();
    } else {
      _loadFirstPage();
    }
  }

  // Loads page 1 and replaces the pre-seeded items with the real first page.
  Future<void> _refreshPage1() async {
    try {
      final items = await widget.pageLoader(1, widget.pageSize);
      if (!mounted) return;
      // API returned nothing but we already have pre-seeded items — keep them
      // instead of showing an empty list, and stop further pagination.
      if (items.isEmpty && _items.isNotEmpty) {
        setState(() => _hasMore = false);
        return;
      }
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _hasMore = items.length >= widget.pageSize;
        _currentPage = 2;
      });
    } catch (_) {
      if (!mounted) return;
      // Keep showing pre-seeded items; stop pagination.
      setState(() => _hasMore = false);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasMore || _isLoadingMore || _isInitialLoading) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 180;
    if (_scrollController.position.pixels >= threshold) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _hasMore = true;
      _currentPage = 1;
      _items.clear();
    });

    try {
      final items = await widget.pageLoader(_currentPage, widget.pageSize);
      if (!mounted) {
        return;
      }

      setState(() {
        _items.addAll(items);
        _hasMore = items.length >= widget.pageSize;
        _currentPage = 2;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.pageLoader(_currentPage, widget.pageSize);
      if (!mounted) {
        return;
      }

      setState(() {
        _items.addAll(items);
        _hasMore = items.length >= widget.pageSize;
        _currentPage += 1;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tìm kiếm ${widget.title.toLowerCase()}...',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isInitialLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_errorMessage != null && _items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadFirstPage,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (_items.isEmpty) {
                  return Center(
                    child: Text(
                      widget.emptyMessage,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, index) =>
                      index == _items.length - 1 && _isLoadingMore
                          ? const SizedBox(height: 12)
                          : const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    if (index >= _items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return widget.itemBuilder(context, _items[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
