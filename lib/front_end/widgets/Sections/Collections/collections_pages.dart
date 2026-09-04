import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/api_service.dart';
import '../../../Provider/api_ready_notifier.dart';
import '../../footer.dart';
import '../../header.dart';
import 'collection_detail_page.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _collections = [];
  bool _loading = true;

  bool _loadTriggered = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ready = context.watch<ApiReadyNotifier>().isReady;
    if (ready && !_loadTriggered) {
      _loadTriggered = true;
      _loadCollections();
    }
  }

  Future<void> _loadCollections() async {
    try {
      final collections = await ApiService.getCollections();
      if (mounted) {
        setState(() {
          _collections = collections
              .map((c) => Map<String, dynamic>.from(c as Map))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading collections: $e');
      if (mounted) {
        setState(() {
          _collections = _fallbackCollections;
          _loading = false;
        });
      }
    }
  }

  final List<Map<String, dynamic>> _fallbackCollections = [
    {'title': 'Fans', 'count': 20, 'icon': Icons.air, 'slug': 'fans'},
    {
      'title': 'Cookers',
      'count': 46,
      'icon': Icons.soup_kitchen,
      'slug': 'cookers',
    },
    {
      'title': 'Blenders',
      'count': 38,
      'icon': Icons.blender,
      'slug': 'blenders',
    },
    {
      'title': 'Phone Related',
      'count': 14,
      'icon': Icons.phone,
      'slug': 'phone-related',
    },
    {
      'title': 'Massager Items',
      'count': 18,
      'icon': Icons.spa,
      'slug': 'massager-items',
    },
    {
      'title': 'Trimmer',
      'count': 15,
      'icon': Icons.content_cut,
      'slug': 'trimmer',
    },
    {
      'title': 'Electric Chula',
      'count': 10,
      'icon': Icons.local_fire_department,
      'slug': 'electric-chula',
    },
    {'title': 'Iron', 'count': 18, 'icon': Icons.iron, 'slug': 'iron'},
    {'title': 'Chopper', 'count': 12, 'icon': Icons.cut, 'slug': 'chopper'},
    {
      'title': 'Grinder',
      'count': 10,
      'icon': Icons.settings,
      'slug': 'grinder',
    },
    {
      'title': 'Kettle',
      'count': 25,
      'icon': Icons.coffee_maker,
      'slug': 'kettle',
    },
    {
      'title': 'Hair Dryer',
      'count': 14,
      'icon': Icons.air,
      'slug': 'hair-dryer',
    },
    {'title': 'Oven', 'count': 8, 'icon': Icons.microwave, 'slug': 'oven'},
    {
      'title': 'Air Fryer',
      'count': 18,
      'icon': Icons.kitchen,
      'slug': 'air-fryer',
    },
  ];

  static const double _tileWidth = 180;

  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - _tileWidth).clamp(
        0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      (_scrollController.offset + _tileWidth).clamp(
        0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _navigateToCategory(Map<String, dynamic> collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionDetailPage(
          collectionName: collection['name'] ?? collection['title'],
          collectionSlug: collection['slug'],
          collectionId: collection['id'] is int
              ? collection['id'] as int
              : (collection['id'] != null
                    ? int.tryParse(collection['id'].toString())
                    : null),
          icon: _getIconFromString(collection['icon']),
        ),
      ),
    );
  }

  IconData _getIconFromString(dynamic iconName) {
    if (iconName == null) return Icons.category;
    final name = iconName.toString().toLowerCase();
    switch (name) {
      case 'air':
        return Icons.air;
      case 'soup_kitchen':
        return Icons.soup_kitchen;
      case 'blender':
        return Icons.blender;
      case 'phone':
        return Icons.phone;
      case 'spa':
        return Icons.spa;
      case 'content_cut':
        return Icons.content_cut;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'iron':
        return Icons.iron;
      case 'cut':
        return Icons.cut;
      case 'settings':
        return Icons.settings;
      case 'coffee_maker':
        return Icons.coffee_maker;
      case 'microwave':
        return Icons.microwave;
      case 'kitchen':
        return Icons.kitchen;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final collections = _loading ? _fallbackCollections : _collections;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shop by Collection',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fast-moving categories with next-day delivery options',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          );

          final controls = Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllCollectionsPage(
                        collections: _loading
                            ? _fallbackCollections
                            : _collections,
                        fallbackCollections: _fallbackCollections,
                        onNavigate: _navigateToCategory,
                        getIcon: _getIconFromString,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View all',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
              ),
              _navButton(Icons.chevron_left, _scrollLeft),
              _navButton(Icons.chevron_right, _scrollRight),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleBlock,
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: controls,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: titleBlock),
                        controls,
                      ],
                    ),
              const SizedBox(height: 12),
              SizedBox(
                height: 104,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 2,
                        ),
                        child: Row(
                          children: collections.map(_categoryTile).toList(),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _categoryTile(Map<String, dynamic> c) {
    final title = c['name'] ?? c['title'] ?? 'Collection';
    final count = c['product_count'] ?? c['item_count'] ?? c['count'] ?? 0;
    final iconData = c['icon'] is IconData
        ? c['icon']
        : _getIconFromString(c['icon']);

    return Container(
      width: _tileWidth,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => _navigateToCategory(c),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0D000000),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count items',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData,
                    size: 22,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

// --- Full-page All Collections -----------------------------------------------

class AllCollectionsPage extends StatefulWidget {
  final List<Map<String, dynamic>> collections;
  final List<Map<String, dynamic>> fallbackCollections;
  final void Function(Map<String, dynamic>) onNavigate;
  final IconData Function(dynamic) getIcon;

  const AllCollectionsPage({
    super.key,
    required this.collections,
    required this.fallbackCollections,
    required this.onNavigate,
    required this.getIcon,
  });

  @override
  State<AllCollectionsPage> createState() => _AllCollectionsPageState();
}

class _AllCollectionsPageState extends State<AllCollectionsPage> {
  List<Map<String, dynamic>> _collections = [];
  bool _loading = true;
  bool _loadTriggered = false;

  @override
  void initState() {
    super.initState();
    // Use already-loaded collections if available
    if (widget.collections.isNotEmpty) {
      _collections = widget.collections;
      _loading = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && !_loadTriggered) {
      final ready = context.watch<ApiReadyNotifier>().isReady;
      if (ready) {
        _loadTriggered = true;
        _loadCollections();
      }
    }
  }

  Future<void> _loadCollections() async {
    try {
      final collections = await ApiService.getCollections();
      if (mounted) {
        setState(() {
          _collections = collections
              .map((c) => Map<String, dynamic>.from(c as Map))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _collections = widget.fallbackCollections;
          _loading = false;
        });
      }
    }
  }

  void _navigate(Map<String, dynamic> collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionDetailPage(
          collectionName: collection['name'] ?? collection['title'],
          collectionSlug: collection['slug'],
          collectionId: collection['id'] is int
              ? collection['id'] as int
              : (collection['id'] != null
                    ? int.tryParse(collection['id'].toString())
                    : null),
          icon: widget.getIcon(collection['icon']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _loading ? widget.fallbackCollections : _collections;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const Header(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              color: const Color(0xFF123456),
              child: const Text(
                'ALL COLLECTIONS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 480 ? 12 : 24,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isPhone = constraints.maxWidth < 480;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isPhone ? 360 : 220,
                        childAspectRatio: isPhone ? 2.4 : 1.6,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final c = items[index];
                        final title = c['name'] ?? c['title'] ?? 'Collection';
                        final count =
                            c['product_count'] ??
                            c['item_count'] ??
                            c['count'] ??
                            0;
                        final iconData = c['icon'] is IconData
                            ? c['icon'] as IconData
                            : widget.getIcon(c['icon']);

                        return InkWell(
                          onTap: () => _navigate(c),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color.fromARGB(255, 197, 111, 105),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x0A000000),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0x12F44336),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    iconData,
                                    size: 24,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$count items',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}









