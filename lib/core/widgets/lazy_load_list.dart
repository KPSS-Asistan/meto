import 'package:flutter/material.dart';

/// Lazy loading list widget
/// Sadece görünen içeriği yükler, scroll'da yeni içerik getirir
class LazyLoadList<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) fetchData;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int pageSize;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final Widget? separator;

  const LazyLoadList({
    super.key,
    required this.fetchData,
    required this.itemBuilder,
    this.pageSize = 20,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.padding,
    this.physics,
    this.separator,
  });

  @override
  State<LazyLoadList<T>> createState() => _LazyLoadListState<T>();
}

class _LazyLoadListState<T> extends State<LazyLoadList<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.fetchData(_currentPage, widget.pageSize);
      
      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length == widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    // Error state
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Hata: $_error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
    }

    // Empty state
    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ??
          const Center(
            child: Text('İçerik bulunamadı'),
          );
    }

    // List
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) {
          if (index < _items.length - 1) {
            return widget.separator ?? const SizedBox.shrink();
          }
          return const SizedBox.shrink();
        },
        itemBuilder: (context, index) {
          // Loading indicator
          if (index >= _items.length) {
            return widget.loadingWidget ??
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
          }

          // Item
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}

/// Lazy load grid widget
class LazyLoadGrid<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) fetchData;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final int pageSize;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final Widget? loadingWidget;
  final Widget? emptyWidget;

  const LazyLoadGrid({
    super.key,
    required this.fetchData,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.pageSize = 20,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.padding,
    this.loadingWidget,
    this.emptyWidget,
  });

  @override
  State<LazyLoadGrid<T>> createState() => _LazyLoadGridState<T>();
}

class _LazyLoadGridState<T> extends State<LazyLoadGrid<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newItems = await widget.fetchData(_currentPage, widget.pageSize);
      
      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length == widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ?? const Center(child: Text('İçerik bulunamadı'));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: widget.childAspectRatio,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
      ),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return widget.loadingWidget ??
              const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        return widget.itemBuilder(context, _items[index], index);
      },
    );
  }
}
