import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/api_service.dart';
import '../utils/auth_session.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final TextEditingController? controller;

  const SearchBarWidget({super.key, required this.onSearch, this.controller});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _overlayActionScheduled = false;

  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _searchHistory = [];
  List<Map<String, dynamic>> _popularSearches = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChange);
    _loadSearchHistory();
    _loadPopularSearches();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    _debounce?.cancel();
    _removeOverlayImmediate();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _removeOverlay();
      });
    }
  }

  Future<void> _loadSearchHistory() async {
    // History endpoint requires authentication — skip for guest users
    final isLoggedIn = await AuthSession.isLoggedIn();
    if (!isLoggedIn) return;

    try {
      final response = await ApiService.get('/search?history=true&limit=5');
      if (response != null && response['history'] != null) {
        if (!mounted) return;
        setState(() {
          _searchHistory = List<Map<String, dynamic>>.from(response['history']);
        });
      }
    } catch (e) {
      // Silently fail — history is a non-critical feature
    }
  }

  Future<void> _loadPopularSearches() async {
    try {
      final response = await ApiService.get('/search?popular=true&limit=5');
      if (response != null && response['popular'] != null) {
        if (!mounted) return;
        setState(() {
          _popularSearches = List<Map<String, dynamic>>.from(
            response['popular'],
          );
        });
      }
    } catch (e) {
      // Silently fail — popular searches is a non-critical feature
    }
  }

  Future<void> _getSuggestions(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      _updateOverlay();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(
        '/search?suggestions=true&q=${Uri.encodeQueryComponent(query)}',
      );
      if (response != null && response['suggestions'] != null) {
        if (!mounted) return;
        setState(() {
          _suggestions = List<Map<String, dynamic>>.from(
            response['suggestions'],
          );
          _isLoading = false;
        });
        _updateOverlay();
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      _updateOverlay();
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _getSuggestions(value);
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    _removeOverlay();
    _focusNode.unfocus();
    widget.onSearch(query.trim());
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _suggestions = [];
    });
    _updateOverlay();
  }

  void _showOverlay() {
    _scheduleOverlayAction(() {
      _removeOverlayImmediate();
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) return;
      _overlayEntry = _createOverlayEntry();
      overlay.insert(_overlayEntry!);
    });
  }

  void _removeOverlay() {
    _scheduleOverlayAction(_removeOverlayImmediate);
  }

  void _removeOverlayImmediate() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _scheduleOverlayAction(() {
      _removeOverlayImmediate();
      if (!_focusNode.hasFocus) return;
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) return;
      _overlayEntry = _createOverlayEntry();
      overlay.insert(_overlayEntry!);
    });
  }

  void _scheduleOverlayAction(VoidCallback action) {
    if (!mounted || _overlayActionScheduled) return;
    _overlayActionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayActionScheduled = false;
      if (!mounted) return;
      action();
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final query = _controller.text.trim();

    if (query.isEmpty) {
      // Show history and popular searches
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchHistory.isNotEmpty) ...[
              _buildSectionHeader('Recent Searches', Icons.history),
              ..._searchHistory.map((item) => _buildHistoryItem(item)),
              const Divider(),
            ],
            if (_popularSearches.isNotEmpty) ...[
              _buildSectionHeader('Popular Searches', Icons.trending_up),
              ..._popularSearches.map((item) => _buildPopularItem(item)),
            ],
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No suggestions found'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return _buildSuggestionItem(suggestion);
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(Map<String, dynamic> suggestion) {
    final type = suggestion['type'] ?? 'product';
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'category':
        icon = Icons.category;
        iconColor = Colors.blue;
        break;
      case 'brand':
        icon = Icons.business;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.search;
        iconColor = Colors.orange;
    }

    return InkWell(
      onTap: () => _performSearch(suggestion['suggestion']),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                suggestion['suggestion'],
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const Icon(Icons.north_west, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return InkWell(
      onTap: () => _performSearch(item['search_query']),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.history, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['search_query'],
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const Icon(Icons.north_west, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularItem(Map<String, dynamic> item) {
    return InkWell(
      onTap: () => _performSearch(item['search_query']),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.trending_up, size: 20, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['search_query'],
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              '${item['search_count']} searches',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        onSubmitted: _performSearch,
        decoration: InputDecoration(
          hintText: 'Search products, brands, categories...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
