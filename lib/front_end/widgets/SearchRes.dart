import 'package:flutter/material.dart';
import 'package:electrocitybd1/config/app_colors.dart';
import '../pages/Templates/all_products_template.dart';
import '../pages/Templates/Dyna_products.dart';
import 'product_card.dart';
import 'header.dart';
import 'footer.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  final List<ProductData> allProducts;

  const SearchResultsPage({
    super.key,
    required this.query,
    required this.allProducts,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  double _priceValue = 50000; // Default max price
  late List<ProductData> filtered;
  int _currentPage = 1;
  final int _itemsPerPage = 15;
  double _maxPrice = 50000;
  double _minPrice = 0;
  bool _mobileFilterOpen = false;

  @override
  void initState() {
    super.initState();
    _calculatePriceRange();
  }

  void _calculatePriceRange() {
    if (widget.allProducts.isEmpty) {
      _minPrice = 0;
      _maxPrice = 50000;
      _priceValue = 50000;
      return;
    }

    final prices = widget.allProducts.map((p) => p.priceBDT).toList();
    _minPrice = prices.reduce((a, b) => a < b ? a : b);
    _maxPrice = prices.reduce((a, b) => a > b ? a : b);

    // Ensure min and max are different
    if (_minPrice == _maxPrice) {
      _minPrice = 0;
      _maxPrice = _maxPrice + 1000;
    }

    // Round up max price to nearest thousand for cleaner slider
    _maxPrice = ((_maxPrice / 1000).ceil() * 1000).toDouble();

    // Ensure max is greater than min
    if (_maxPrice <= _minPrice) {
      _maxPrice = _minPrice + 1000;
    }

    _priceValue = _maxPrice;
  }

  @override
  Widget build(BuildContext context) {
    filtered = _rankedSearchResults();

    const Color brandOrange = Color(0xFFF59E0B);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const Header(),
      // Mobile filter drawer
      endDrawer: isMobile
          ? Drawer(
              width: MediaQuery.of(context).size.width * 0.85,
              child: SafeArea(child: _buildFilterSidebar(brandOrange)),
            )
          : null,
      body: Column(
        children: [
          // Search Title Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.grey300,
              border: Border(bottom: BorderSide(color: AppColors.grey300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Search Results for: "${widget.query}"',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey300,
                    ),
                  ),
                ),
                // Mobile filter button
                if (isMobile)
                  Builder(
                    builder: (ctx) => OutlinedButton.icon(
                      onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Filter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brandOrange,
                        side: BorderSide(color: brandOrange),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Main Content with Footer
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT SIDEBAR: FILTERS ? desktop only
                      if (!isMobile) _buildFilterSidebar(brandOrange),

                      // RIGHT SIDE: PRODUCT GRID
                      Expanded(
                        child: filtered.isEmpty
                            ? SizedBox(
                                height: 400,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.search_off,
                                        size: 80,
                                        color: AppColors.grey300,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No products found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: AppColors.grey300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.all(isMobile ? 12 : 20),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: _getGridCount(
                                            context,
                                          ),
                                          childAspectRatio: _getCardAspectRatio(
                                            context,
                                          ),
                                          crossAxisSpacing: isMobile ? 8 : 12,
                                          mainAxisSpacing: isMobile ? 8 : 12,
                                        ),
                                    itemCount: _getPaginatedProducts().length,
                                    itemBuilder: (context, i) {
                                      final product =
                                          _getPaginatedProducts()[i];
                                      final stockQty =
                                          int.tryParse(
                                            product.additionalInfo['stock_quantity']
                                                    ?.toString() ??
                                                product.additionalInfo['stock']
                                                    ?.toString() ??
                                                '0',
                                          ) ??
                                          0;
                                      return ProductCard(
                                        title: product.name,
                                        price: product.priceBDT,
                                        imageUrl: product.images.isNotEmpty
                                            ? product.images[0]
                                            : '',
                                        stockQuantity: stockQty,
                                        onPress: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  UniversalProductDetails(
                                                    product: product,
                                                  ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),

                                  // Pagination Controls
                                  if (_getTotalPages() > 1)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 24,
                                        horizontal: 20,
                                      ),
                                      child: _buildPagination(),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),

                  // Footer at the bottom
                  const FooterSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ProductData> _rankedSearchResults() {
    final query = _normalizeSearchText(widget.query);
    final queryTokens = _expandQueryTokens(_tokenize(query));

    final matches = <_SearchMatch>[];
    for (final product in widget.allProducts) {
      if (product.priceBDT > _priceValue) continue;

      if (queryTokens.isEmpty) {
        matches.add(_SearchMatch(product, 0));
        continue;
      }

      final score = _scoreProduct(product, query, queryTokens);
      if (score > 0) matches.add(_SearchMatch(product, score));
    }

    matches.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.product.priceBDT.compareTo(b.product.priceBDT);
    });

    return matches.map((m) => m.product).toList();
  }

  int _scoreProduct(
    ProductData product,
    String query,
    List<String> queryTokens,
  ) {
    final brand = product.additionalInfo['brand'] ?? '';
    final productName = _normalizeSearchText(product.name);
    final productCategory = _normalizeSearchText(product.category);

    final fields = <_SearchField>[
      _SearchField(productName, 120),
      _SearchField(_normalizeSearchText(brand), 85),
      _SearchField(productCategory, 70),
      _SearchField(_normalizeSearchText(product.description), 20),
      _SearchField(
        _normalizeSearchText(product.additionalInfo.values.join(' ')),
        12,
      ),
    ];

    final combined = fields.map((f) => f.text).join(' ');
    final combinedTokens = _tokenize(combined);
    if (combinedTokens.isEmpty) return 0;

    // ? CRITICAL: Check if query keyword exists in product name or category
    // If not in name/category, reject the result (unless it's an exact brand match)
    final hasMainKeyword =
        productName.contains(query) ||
        productCategory.contains(query) ||
        productName
            .split(' ')
            .any((word) => queryTokens.any((term) => word.startsWith(term)));

    if (!hasMainKeyword && brand.toLowerCase() != query.toLowerCase()) {
      return 0; // Reject if keyword not in main fields
    }

    var score = 0;
    var matchedTerms = 0;

    // Score product name matches MUCH higher
    if (productName == query) score += 800;
    if (productName.startsWith(query)) score += 600;
    if (productName.contains(query)) score += 400;

    // Score category matches highly
    if (productCategory.contains(query)) score += 250;

    // Score brand matches
    if (brand.toLowerCase() == query.toLowerCase()) score += 300;
    if (brand.toLowerCase().startsWith(query.toLowerCase())) score += 200;

    for (final field in fields) {
      if (field.text.isEmpty) continue;
      if (field.text == query) score += field.weight * 80;
      if (field.text.startsWith(query)) score += field.weight * 45;
      if (field.text.contains(query) && field.weight >= 70)
        score += field.weight * 26; // Only for important fields
    }

    for (final term in queryTokens) {
      final best = _bestTokenScore(term, fields, combinedTokens);
      if (best > 0) {
        matchedTerms++;
        score += best;
      }
    }

    if (matchedTerms == queryTokens.length) {
      score += 900 + (queryTokens.length * 120);
    } else if (queryTokens.length > 1) {
      score -= (queryTokens.length - matchedTerms) * 360; // Stricter penalty
    }

    if (matchedTerms == 0) return 0;

    // Stricter minimum score threshold
    if (queryTokens.length == 1 &&
        queryTokens.first.length >= 3 &&
        score < 350) {
      return 0;
    }

    return score;
  }

  int _bestTokenScore(
    String term,
    List<_SearchField> fields,
    List<String> combinedTokens,
  ) {
    var best = 0;

    for (final field in fields) {
      if (field.text.isEmpty) continue;
      final fieldTokens = _tokenize(field.text);

      if (field.text.split(' ').contains(term)) {
        best = best > field.weight * 20 ? best : field.weight * 20;
      } else if (field.text.startsWith(term)) {
        best = best > field.weight * 15 ? best : field.weight * 15;
      } else if (field.text.contains(term)) {
        best = best > field.weight * 8 ? best : field.weight * 8;
      }

      for (final token in fieldTokens) {
        if (token == term) {
          best = best > field.weight * 22 ? best : field.weight * 22;
          continue;
        }
        if (token.startsWith(term) || term.startsWith(token)) {
          best = best > field.weight * 16 ? best : field.weight * 16;
          continue;
        }
        if (term.length >= 3 && token.contains(term)) {
          best = best > field.weight * 9 ? best : field.weight * 9;
          continue;
        }
      }
    }

    if (term.length >= 4) {
      for (final token in combinedTokens) {
        final maxDistance = term.length <= 5 ? 1 : 2;
        if (_levenshteinDistance(term, token, maxDistance) <= maxDistance) {
          best = best > 420 ? best : 420;
        }
      }
    }

    return best;
  }

  String _normalizeSearchText(String value) {
    final lower = value.toLowerCase().trim();
    return lower
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9\u0980-\u09FF]+', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _tokenize(String value) {
    if (value.isEmpty) return const [];
    return value
        .split(' ')
        .where((token) => token.isNotEmpty)
        .map(_normalizeToken)
        .where((token) => token.isNotEmpty && !_stopWords.contains(token))
        .toList();
  }

  String _normalizeToken(String token) {
    const singularSuffixes = ['ies', 'es', 's'];
    var normalized = token.trim();
    if (normalized.length > 4 && normalized.endsWith(singularSuffixes[0])) {
      normalized = '${normalized.substring(0, normalized.length - 3)}y';
    } else if (normalized.length > 4 &&
        normalized.endsWith(singularSuffixes[1])) {
      normalized = normalized.substring(0, normalized.length - 2);
    } else if (normalized.length > 3 &&
        normalized.endsWith(singularSuffixes[2])) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  List<String> _expandQueryTokens(List<String> tokens) {
    final expanded = <String>{};
    for (final token in tokens) {
      expanded.add(token);
      final aliases = _searchAliases[token];
      if (aliases != null) expanded.addAll(aliases);
    }
    return expanded.toList();
  }

  int _levenshteinDistance(String a, String b, int maxDistance) {
    if ((a.length - b.length).abs() > maxDistance) return maxDistance + 1;
    if (a == b) return 0;

    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i + 1;
      var rowMin = current[0];

      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        final insert = current[j] + 1;
        final delete = previous[j + 1] + 1;
        final replace = previous[j] + cost;
        final value = [insert, delete, replace].reduce((x, y) => x < y ? x : y);
        current[j + 1] = value;
        if (value < rowMin) rowMin = value;
      }

      if (rowMin > maxDistance) return maxDistance + 1;
      previous = current;
    }

    return previous[b.length];
  }

  // Filter Sidebar UI - Only Price Range
  Widget _buildFilterSidebar(Color orange) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.grey300)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Filters",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 40),

            // Price Range Slider
            const Text(
              "Price Range",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _priceValue.clamp(_minPrice, _maxPrice),
              min: _minPrice,
              max: _maxPrice,
              divisions: ((_maxPrice - _minPrice) / 1000).round().clamp(1, 100),
              activeColor: orange,
              inactiveColor: AppColors.grey300,
              label: "Tk ${_priceValue.round()}",
              onChanged: (val) => setState(() {
                _priceValue = val;
                _currentPage = 1; // Reset to first page when filter changes
              }),
            ),
            Text(
              "Tk ${_minPrice.round()} - Tk ${_priceValue.round()}",
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey300,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "${filtered.length} products found",
              style: TextStyle(fontSize: 14, color: AppColors.grey300),
            ),
          ],
        ),
      ),
    );
  }

  int _getGridCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 480) return 2;
    if (w < 768) return 2; // keep product cards readable on phones
    if (w < 900) return 3;
    if (w < 1200) return 4;
    return 5;
  }

  double _getCardAspectRatio(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 480) return 0.64;
    if (w < 768) return 0.68;
    return 0.58;
  }

  // Pagination helpers
  int _getTotalPages() {
    return (filtered.length / _itemsPerPage).ceil();
  }

  List<ProductData> _getPaginatedProducts() {
    if (filtered.isEmpty) return [];
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    // Ensure we don't go out of bounds
    if (startIndex >= filtered.length) {
      _currentPage = 1;
      return filtered.sublist(
        0,
        _itemsPerPage > filtered.length ? filtered.length : _itemsPerPage,
      );
    }

    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  Widget _buildPagination() {
    final totalPages = _getTotalPages();
    const Color brandOrange = Color(0xFFF59E0B);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous button
        IconButton(
          onPressed: _currentPage > 1
              ? () => setState(() => _currentPage--)
              : null,
          icon: const Icon(Icons.chevron_left),
          color: brandOrange,
          disabledColor: AppColors.grey300,
        ),

        const SizedBox(width: 8),

        // Page numbers
        ...List.generate(totalPages, (index) {
          final pageNum = index + 1;
          final isCurrentPage = pageNum == _currentPage;

          // Show first, last, current, and adjacent pages
          if (pageNum == 1 ||
              pageNum == totalPages ||
              (pageNum >= _currentPage - 1 && pageNum <= _currentPage + 1)) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => setState(() => _currentPage = pageNum),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrentPage ? brandOrange : Colors.transparent,
                    border: Border.all(
                      color: isCurrentPage ? brandOrange : AppColors.grey200,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      color: isCurrentPage ? Colors.white : AppColors.grey200,
                      fontWeight: isCurrentPage
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          } else if (pageNum == _currentPage - 2 ||
              pageNum == _currentPage + 2) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...', style: TextStyle(fontSize: 18)),
            );
          }
          return const SizedBox.shrink();
        }),

        const SizedBox(width: 8),

        // Next button
        IconButton(
          onPressed: _currentPage < totalPages
              ? () => setState(() => _currentPage++)
              : null,
          icon: const Icon(Icons.chevron_right),
          color: brandOrange,
          disabledColor: AppColors.grey300,
        ),
      ],
    );
  }
}

class _SearchMatch {
  final ProductData product;
  final int score;

  const _SearchMatch(this.product, this.score);
}

class _SearchField {
  final String text;
  final int weight;

  const _SearchField(this.text, this.weight);
}

const _stopWords = <String>{
  'a',
  'an',
  'and',
  'for',
  'in',
  'of',
  'on',
  'the',
  'to',
  'with',
};

const _searchAliases = <String, List<String>>{
  'ac': ['air', 'conditioner'],
  'aircon': ['air', 'conditioner', 'ac'],
  'conditioner': ['ac'],
  'mobile': ['phone', 'smartphone'],
  'phone': ['mobile', 'smartphone'],
  'smartphone': ['mobile', 'phone'],
  'tv': ['television'],
  'television': ['tv'],
  'fridge': ['refrigerator'],
  'refrigerator': ['fridge'],
  'earbud': ['earphone', 'headphone'],
  'earphone': ['earbud', 'headphone'],
  'headphone': ['earphone', 'earbud'],
  'laptop': ['notebook'],
  'notebook': ['laptop'],
};
