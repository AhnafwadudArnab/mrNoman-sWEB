import 'package:flutter/material.dart';
import '../../../Front-end/utils/api_service.dart';
import '../../../Front-end/utils/image_resolver.dart';

class PromotionsPage extends StatefulWidget {
  final String title;
  const PromotionsPage({super.key, this.title = 'Promotions'});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  List<Map<String, dynamic>> _promotions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.getPromotions();
      if (mounted) {
        setState(() {
          _promotions = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _promotions.isEmpty
              ? const Center(child: Text('No promotions available right now.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Current Promotions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore our limited-time offers and best deals across categories.',
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ..._promotions.map((p) {
                      final title = (p['title'] ?? 'Promotion').toString();
                      final desc = (p['description'] ?? '').toString();
                      final percent = p['discount_percent'];
                      final imageUrl = (p['image_url'] ?? '').toString();
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    ImageResolver.resolveUrl(imageUrl),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 56,
                                      height: 56,
                                      color: Colors.orange.shade50,
                                      child: const Icon(Icons.local_offer, color: Colors.orange),
                                    ),
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.orange.shade50,
                                    child: const Icon(Icons.local_offer, color: Colors.orange),
                                  ),
                          ),
                          title: Text(title),
                          subtitle: Text(
                            percent != null ? '$desc${desc.isNotEmpty ? ' • ' : ''}$percent% off' : desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
