import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/api_service.dart';
import '../utils/image_resolver.dart';
import 'admin_theme.dart';

class AdminBrandingLogoPage extends StatefulWidget {
  final bool embedded;
  const AdminBrandingLogoPage({super.key, this.embedded = false});

  @override
  State<AdminBrandingLogoPage> createState() => _AdminBrandingLogoPageState();
}

class _AdminBrandingLogoPageState extends State<AdminBrandingLogoPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _brandLogos = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBrandLogos();
  }

  Future<void> _loadBrandLogos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('/brands', withAuth: true);

      if (response is List) {
        setState(() {
          _brandLogos = response
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _loading = false;
        });
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Brand logos load error: $e');
      setState(() {
        _error = 'Error loading brand logos: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _addBrandLogo() async {
    final nameController = TextEditingController();
    final logoController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Brand Logo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Brand Name',
                hintText: 'e.g., Samsung, LG, Walton',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: logoController,
              decoration: const InputDecoration(
                labelText: 'Logo URL',
                hintText: 'assets/Brand Logo/walton.png',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter brand name')),
                );
                return;
              }

              try {
                await ApiService.post('/brands', {
                  'brand_name': nameController.text,
                  'brand_logo': logoController.text,
                }, withAuth: true);
                if (!context.mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadBrandLogos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brand logo added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editBrandLogo(Map<String, dynamic> brand) async {
    final nameController = TextEditingController(text: brand['brand_name']);
    final logoController = TextEditingController(
      text: brand['brand_logo'] ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Brand Logo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Brand Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: logoController,
              decoration: const InputDecoration(labelText: 'Logo URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.put('/brands/${brand['brand_id']}', {
                  'brand_name': nameController.text,
                  'brand_logo': logoController.text,
                });
                if (!context.mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadBrandLogos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brand logo updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteBrandLogo(Map<String, dynamic> brand) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Brand Logo'),
        content: Text(
          'Are you sure you want to delete ${brand['brand_name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.delete('/brands/${brand['brand_id']}');
        _loadBrandLogos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brand logo deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardBg = AdminTheme.surfaceAlt;
    const brandOrange = Color(0xFF7C3AED);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration:  BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: Color(0x0D000000))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
               Flexible(
                child: Text(
                  'Management / Branding Logo',
                  style: TextStyle(color: Color(0x73000000), fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addBrandLogo,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Logo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red[100],
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: _loadBrandLogos,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        Expanded(
          child: _brandLogos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Brand Logos Yet',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Add Brand Logo" to get started',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addBrandLogo,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Brand Logo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandOrange,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth < 400
                          ? 2
                          : constraints.maxWidth < 700
                          ? 3
                          : 4;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _brandLogos.length,
                        itemBuilder: (context, index) {
                          final brand = _brandLogos[index];
                          return Card(
                            elevation: 2,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child:
                                        brand['brand_logo'] != null &&
                                            brand['brand_logo']
                                                .toString()
                                                .isNotEmpty
                                        ? ImageResolver.image(
                                            imageUrl: brand['brand_logo']
                                                .toString(),
                                            fit: BoxFit.contain,
                                            placeholder: Icon(
                                              Icons.image_not_supported,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                          )
                                        : Icon(
                                            Icons.business,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    border: Border(
                                      top: BorderSide(color: Colors.grey[300]!),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        brand['brand_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${brand['product_count'] ?? 0} products',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                _editBrandLogo(brand),
                                            tooltip: 'Edit',
                                            color: Colors.blue,
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                _deleteBrandLogo(brand),
                                            tooltip: 'Delete',
                                            color: Colors.red,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );

    if (widget.embedded) {
      return Material(
        color: AdminTheme.bg,
        child: SizedBox.expand(child: content),
      );
    }
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: content,
    );
  }
}









