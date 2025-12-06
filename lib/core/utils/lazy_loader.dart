import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Lazy loading helper - Academic Premium style
class LazyLoader<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) loadMore;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final int pageSize;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;

  const LazyLoader({
    super.key,
    required this.loadMore,
    required this.itemBuilder,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.pageSize = 20,
    this.scrollController,
    this.padding,
  });

  @override
  State<LazyLoader<T>> createState() => _LazyLoaderState<T>();
}

class _LazyLoaderState<T> extends State<LazyLoader<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.loadMore(0, widget.pageSize);
      setState(() {
        _items.clear();
        _items.addAll(items);
        _currentPage = 0;
        _hasMore = items.length >= widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final items = await widget.loadMore(_currentPage + 1, widget.pageSize);
      setState(() {
        _items.addAll(items);
        _currentPage++;
        _hasMore = items.length >= widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInitial,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
    }

    if (_items.isEmpty && _isLoading) {
      return widget.loadingWidget ??
          Center(
            child: Platform.isIOS
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(),
          );
    }

    if (_items.isEmpty) {
      return widget.emptyWidget ??
          const Center(child: Text('Veri bulunamadı'));
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView.builder(
        controller: widget.scrollController ?? _scrollController,
        padding: widget.padding,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Platform.isIOS
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(),
              ),
            );
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}

/// Pagination helper
class PaginationHelper<T> {
  final List<T> allItems;
  final int pageSize;

  PaginationHelper({
    required this.allItems,
    this.pageSize = 20,
  });

  /// Get page
  List<T> getPage(int page) {
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, allItems.length);
    
    if (start >= allItems.length) return [];
    
    return allItems.sublist(start, end);
  }

  /// Get total pages
  int get totalPages => (allItems.length / pageSize).ceil();

  /// Check if has more
  bool hasMore(int currentPage) => currentPage < totalPages - 1;
}
