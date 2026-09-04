import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_customers.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';
import 'package:electrocitybd1/front_end/Provider/Banner_provider.dart';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/utils/image_resolver.dart';

class AdminBannersPage extends StatefulWidget {
  final bool embedded;

  const AdminBannersPage({super.key, this.embedded = false});

  @override
  State<AdminBannersPage> createState() => _AdminBannersPageState();
}

class _AdminBannersPageState extends State<AdminBannersPage> {
  bool _uploading = false;
  bool _midUploading = false;

  /// Uploads a local file to the server and returns the URL, or throws on failure.
  Future<String> _uploadFile(
    String? filePath, {
    Uint8List? bytes,
    String? fileName,
  }) async {
    final url = Uri.parse(ApiService.getUploadUrl());
    final request = http.MultipartRequest('POST', url);
    // Add auth token so the upload endpoint can verify admin identity
    final token = await ApiService.getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    if (kIsWeb && bytes != null && fileName != null) {
      // Web: use bytes directly
      request.files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: fileName),
      );
    } else {
      if (filePath == null || filePath.isEmpty) {
        throw Exception('File path is missing for native upload');
      }
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(respStr) as Map);
        final u = map['url']?.toString();
        if (u != null && u.isNotEmpty) return u;
      } catch (_) {
        final u = RegExp(
          r'"url"\s*:\s*"([^"]+)"',
        ).firstMatch(respStr)?.group(1);
        if (u != null && u.isNotEmpty) return u;
      }
    }
    throw Exception('Upload failed (${response.statusCode}): $respStr');
  }

  Future<void> _pickHeroImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      String imgUrl;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) return;
        imgUrl = await _uploadFile(null, bytes: bytes, fileName: file.name);
      } else {
        final nativePath = file.path;
        if (nativePath == null) return;
        imgUrl = await _uploadFile(nativePath);
      }
      if (mounted) {
        setState(() => _heroImageController.text = imgUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickMidImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;

    setState(() => _midUploading = true);
    try {
      String imgUrl;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) return;
        imgUrl = await _uploadFile(null, bytes: bytes, fileName: file.name);
      } else {
        final nativePath = file.path;
        if (nativePath == null) return;
        imgUrl = await _uploadFile(nativePath);
      }
      if (mounted) {
        setState(() => _midImageController.text = imgUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mid banner image uploaded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _midUploading = false);
    }
  }

  final Color darkBg = AdminTheme.bg;
  final Color cardBg = AdminTheme.surfaceAlt;
  final Color brandOrange = const Color(0xFF7C3AED);

  final TextEditingController _heroImageController = TextEditingController();
  final TextEditingController _heroLabelController = TextEditingController();
  final TextEditingController _midImageController = TextEditingController();
  final List<TextEditingController> _midControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final TextEditingController _sidebarTitleController = TextEditingController();
  final TextEditingController _sidebarSubtitleController =
      TextEditingController();
  final TextEditingController _sidebarButtonController =
      TextEditingController();
  String _sidebarSource = 'flash-sale';
  bool _sidebarProductsLoading = false;
  List<Map<String, dynamic>> _sidebarProducts = [];
  final Set<String> _sidebarSelectedProductIds = {};

  int? _editingHeroIndex;
  int? _midEditingIndex;
  bool _heroFormVisible = false;
  bool _midFormVisible = false;
  bool _syncedFromProvider = false;

  String _resolvePreviewUrl(String path) {
    return ImageResolver.resolveUrl(path);
  }

  bool _isNetworkOrUploadPath(String path) {
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('/uploads/') ||
        path.startsWith('/api/uploads/') ||
        path.startsWith('/api/public/uploads/') ||
        path.startsWith('uploads/');
  }

  Widget _buildBannerPreview(
    String path, {
    double height = 150,
    String emptyText = 'Upload or enter an image path to preview it here',
    BoxFit fit = BoxFit.cover,
  }) {
    final cleanPath = path.trim();
    final preview = cleanPath.isEmpty
        ? Center(
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
            ),
          )
        : _isNetworkOrUploadPath(cleanPath)
        ? Image.network(
            _resolvePreviewUrl(cleanPath),
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.redAccent),
            ),
          )
        : cleanPath.startsWith('assets/')
        ? Image.asset(
            cleanPath,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.redAccent),
            ),
          )
        : kIsWeb
        ? Center(child: Icon(Icons.image, color: AdminTheme.textMuted))
        : Image.file(
            File(cleanPath),
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.redAccent),
            ),
          );

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: preview,
    );
  }

  Widget _buildControllerPreview(TextEditingController controller) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return _buildBannerPreview(value.text);
      },
    );
  }

  Widget _buildMidControllerPreview(TextEditingController controller) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return _buildBannerPreview(
          value.text,
          height: 110,
          fit: BoxFit.contain,
          emptyText: 'Mid banner preview. Recommended 720 x 320 px.',
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Ensure BannerProvider is loaded
    Future.microtask(() => context.read<BannerProvider>().load());
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromProvider());
  }

  void _ensureSyncedFromProvider(BannerProvider bp) {
    if (!(bp.loaded ?? false) || _syncedFromProvider) return;
    _syncedFromProvider = true;
    _midControllers[0].text = bp.midBanners.isNotEmpty
        ? (bp.midBanners[0]['img'] ?? '')
        : '';
    if (bp.midBanners.length > 1) {
      _midControllers[1].text = bp.midBanners[1]['img'] ?? '';
    }
    if (bp.midBanners.length > 2) {
      _midControllers[2].text = bp.midBanners[2]['img'] ?? '';
    }
    _sidebarTitleController.text = bp.sidebarTitle;
    _sidebarSubtitleController.text = bp.sidebarSubtitle;
    _sidebarButtonController.text = bp.sidebarButtonText;
    _sidebarSource = bp.sidebarSource;
    _sidebarSelectedProductIds
      ..clear()
      ..addAll(bp.sidebarProductIds);
    _loadSidebarProducts();
    if (mounted) setState(() {});
  }

  void _syncFromProvider() {
    final bp = context.read<BannerProvider>();
    if (!(bp.loaded ?? false)) return;
    _syncedFromProvider = true;
    _midControllers[0].text = bp.midBanners.isNotEmpty
        ? (bp.midBanners[0]['img'] ?? '')
        : '';
    if (bp.midBanners.length > 1) {
      _midControllers[1].text = bp.midBanners[1]['img'] ?? '';
    }
    if (bp.midBanners.length > 2) {
      _midControllers[2].text = bp.midBanners[2]['img'] ?? '';
    }
    _sidebarTitleController.text = bp.sidebarTitle;
    _sidebarSubtitleController.text = bp.sidebarSubtitle;
    _sidebarButtonController.text = bp.sidebarButtonText;
    _sidebarSource = bp.sidebarSource;
    _sidebarSelectedProductIds
      ..clear()
      ..addAll(bp.sidebarProductIds);
    _loadSidebarProducts();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _heroImageController.dispose();
    _heroLabelController.dispose();
    _midImageController.dispose();
    for (final c in _midControllers) {
      c.dispose();
    }
    _sidebarTitleController.dispose();
    _sidebarSubtitleController.dispose();
    _sidebarButtonController.dispose();
    super.dispose();
  }

  void _navigate(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.banners) return;
    AdminNav.go(context, item);
  }

  String _productId(Map<String, dynamic> p) =>
      (p['product_id'] ?? p['id'] ?? p['deal_id'] ?? '').toString();

  String _productName(Map<String, dynamic> p) =>
      (p['product_name'] ?? p['name'] ?? p['title'] ?? 'Untitled product')
          .toString();

  Future<void> _loadSidebarProducts() async {
    if (!mounted) return;
    setState(() => _sidebarProductsLoading = true);
    try {
      dynamic response;
      switch (_sidebarSource) {
        case 'trending':
          response = await ApiService.getProducts(
            section: 'trending',
            limit: 100,
            fresh: true,
          );
          break;
        case 'deals':
          response = await ApiService.getDeals(
            limit: 100,
            useCache: false,
            includeExpired: true,
          );
          break;
        case 'all':
          response = await ApiService.getProducts(limit: 200, fresh: true);
          break;
        case 'flash-sale':
        default:
          response = await ApiService.getProducts(
            section: 'flash-sale',
            limit: 100,
            fresh: true,
          );
      }

      final rawList = response is List
          ? response
          : (response is Map ? (response['products'] as List? ?? []) : []);
      final products = rawList
          .whereType<Map>()
          .map((p) => Map<String, dynamic>.from(p))
          .where((p) => _productId(p).isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _sidebarProducts = products;
        _sidebarProductsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sidebarProducts = [];
        _sidebarProductsLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load $_sidebarSource products: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(),
                const SizedBox(height: 28),
                _buildMidSection(),
                const SizedBox(height: 28),
                _buildSidebarPromoSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() => AdminPageHeader(
    color: cardBg,
    children: [
      Text(
        "Management / Banners",
        style: TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
      ),
      const SizedBox.shrink(),
    ],
  );

  Widget _buildHeroSection() {
    return Consumer<BannerProvider>(
      builder: (context, bp, _) {
        final slides = (bp.heroSlides ?? []);
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    "Hero Banners (Home page carousel)",
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _heroFormVisible = true;
                        _editingHeroIndex = null;
                        _heroImageController.clear();
                        _heroLabelController.clear();
                      });
                    },
                    icon: const Icon(
                      Icons.add,
                      color: AdminTheme.textPrimary,
                      size: 18,
                    ),
                    label: const Text("Add slide"),
                    style: TextButton.styleFrom(foregroundColor: brandOrange),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_heroFormVisible || _editingHeroIndex != null) ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final imageField = Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _heroImageController,
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Image path or pick file',
                              labelStyle: TextStyle(color: AdminTheme.textSecondary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: AdminTheme.textSecondary),
                              ),
                              suffixIcon: _uploading
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.folder_open,
                                        color: AdminTheme.textPrimary,
                                      ),
                                      onPressed: _pickHeroImage,
                                      tooltip: 'Pick image from computer',
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildControllerPreview(_heroImageController),
                        ],
                      ),
                    );
                    final labelField = Expanded(
                      child: TextField(
                        controller: _heroLabelController,
                        style: const TextStyle(color: AdminTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Label',
                          labelStyle: TextStyle(color: AdminTheme.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AdminTheme.textSecondary),
                          ),
                        ),
                      ),
                    );
                    final saveBtn = IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: _uploading
                          ? null
                          : () async {
                              final img = _heroImageController.text.trim();
                              final label = _heroLabelController.text.trim();
                              if (img.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please pick or enter an image first.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              final newSlides = List<Map<String, String>>.from(
                                slides,
                              );
                              final entry = {
                                'image': img,
                                'label': label.isEmpty ? 'OFFER' : label,
                              };
                              if (_editingHeroIndex != null) {
                                newSlides[_editingHeroIndex!] = entry;
                              } else {
                                newSlides.add(entry);
                              }
                              final ok = await bp.saveHero(newSlides);
                              if (ok && mounted) await bp.load(force: true);
                              setState(() {
                                _heroFormVisible = false;
                                _editingHeroIndex = null;
                                _heroImageController.clear();
                                _heroLabelController.clear();
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Hero banner saved and live on website!'
                                          : 'Saved locally, but server sync failed.',
                                    ),
                                    backgroundColor: ok
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                );
                              }
                            },
                    );
                    final cancelBtn = IconButton(
                      icon: Icon(Icons.close, color: AdminTheme.textSecondary),
                      onPressed: () => setState(() {
                        _heroFormVisible = false;
                        _editingHeroIndex = null;
                        _heroImageController.clear();
                        _heroLabelController.clear();
                      }),
                    );
                    return isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [imageField]),
                              const SizedBox(height: 8),
                              Row(children: [labelField]),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [saveBtn, cancelBtn],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              imageField,
                              const SizedBox(width: 16),
                              labelField,
                              const SizedBox(width: 8),
                              saveBtn,
                              cancelBtn,
                            ],
                          );
                  },
                ),
                const SizedBox(height: 16),
              ],
              ...slides.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: darkBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}.',
                        style: TextStyle(
                          color: AdminTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: _buildBannerPreview(
                          s['image'] ?? '',
                          height: 54,
                          emptyText: 'No image',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (s['label'] ?? '').isEmpty
                                  ? 'Untitled slide'
                                  : s['label']!,
                              style: TextStyle(
                                color: brandOrange,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s['image'] ?? '',
                              style: TextStyle(
                                color: AdminTheme.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _editingHeroIndex = i;
                            _heroFormVisible = true;
                            _heroImageController.text = s['image'] ?? '';
                            _heroLabelController.text = s['label'] ?? '';
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () async {
                          final newSlides = List<Map<String, String>>.from(
                            slides,
                          )..removeAt(i);
                          final ok = await bp.saveHero(newSlides);
                          if (ok && mounted) await bp.load(force: true);
                          if (_editingHeroIndex == i) {
                            setState(() {
                              _editingHeroIndex = null;
                              _heroImageController.clear();
                              _heroLabelController.clear();
                            });
                          } else {
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),
              if (slides.isEmpty && !_heroFormVisible)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "No hero slides. Click \"Add slide\" to add one.",
                    style: TextStyle(color: AdminTheme.textSecondary),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMidSection() {
    return Consumer<BannerProvider>(
      builder: (context, bp, _) {
        if ((bp.loaded ?? false) && !_syncedFromProvider) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _ensureSyncedFromProvider(context.read<BannerProvider>());
            }
          });
        }

        final midBanners = bp.midBanners;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    "Mid Banners (Dynamic list below Flash_Sale)",
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _midEditingIndex = midBanners.length;
                        _midFormVisible = true;
                        _midImageController.clear();
                      });
                    },
                    icon: const Icon(
                      Icons.add,
                      color: AdminTheme.textPrimary,
                      size: 18,
                    ),
                    label: const Text("Add banner"),
                    style: TextButton.styleFrom(foregroundColor: brandOrange),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Recommended mid_banner image: 720 x 320 px for web, 440 x 200 px mobile-safe. Keep key text/logo centered; images display zoomed out without cropping.',
                style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Add/Edit Form
              if (_midFormVisible || _midEditingIndex != null) ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final imageField = Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _midImageController,
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Image path or pick file',
                              labelStyle: TextStyle(color: AdminTheme.textSecondary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: AdminTheme.textSecondary),
                              ),
                              suffixIcon: _midUploading
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.folder_open,
                                        color: AdminTheme.textPrimary,
                                      ),
                                      onPressed: () => _pickMidImage(),
                                      tooltip: 'Pick image from computer',
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildMidControllerPreview(_midImageController),
                        ],
                      ),
                    );
                    final saveBtn = IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: _midUploading
                          ? null
                          : () async {
                              final img = _midImageController.text.trim();
                              if (img.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please pick or enter an image first.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              final newBanners = List<Map<String, String>>.from(
                                midBanners,
                              );
                              final entry = {'img': img, 'image': img};
                              if (_midEditingIndex != null &&
                                  _midEditingIndex! < newBanners.length) {
                                newBanners[_midEditingIndex!] = entry;
                              } else {
                                newBanners.add(entry);
                              }
                              final ok = await bp.saveMid(newBanners);
                              if (ok && mounted) await bp.load(force: true);
                              setState(() {
                                _midFormVisible = false;
                                _midEditingIndex = null;
                                _midImageController.clear();
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Mid banner saved and synced to website!'
                                          : 'Saved locally, but server sync failed. Please login again and retry.',
                                    ),
                                    backgroundColor: ok
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                );
                              }
                            },
                    );
                    final cancelBtn = IconButton(
                      icon: Icon(Icons.close, color: AdminTheme.textSecondary),
                      onPressed: () => setState(() {
                        _midFormVisible = false;
                        _midEditingIndex = null;
                        _midImageController.clear();
                      }),
                    );
                    return isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [imageField]),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [saveBtn, cancelBtn],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              imageField,
                              const SizedBox(width: 8),
                              saveBtn,
                              cancelBtn,
                            ],
                          );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // List of existing mid banners
              ...midBanners.asMap().entries.map((e) {
                final i = e.key;
                final banner = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: darkBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 520;
                      final actions = Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blue,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _midEditingIndex = i;
                                _midFormVisible = true;
                                _midImageController.text =
                                    (banner['img'] ?? banner['image'] ?? '');
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () async {
                              final newBanners = List<Map<String, String>>.from(
                                midBanners,
                              )..removeAt(i);
                              final ok = await bp.saveMid(newBanners);
                              if (ok && mounted) await bp.load(force: true);
                              if (_midEditingIndex == i) {
                                setState(() {
                                  _midEditingIndex = null;
                                  _midImageController.clear();
                                });
                              } else {
                                setState(() {});
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Mid banner deleted and synced!'
                                          : 'Deleted locally, but server sync failed. Please retry.',
                                    ),
                                    backgroundColor: ok
                                        ? Colors.orange
                                        : Colors.redAccent,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                      final text = Text(
                        (banner['img'] ?? banner['image'] ?? ''),
                        style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
                        maxLines: isCompact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      );
                      final imagePath = banner['img'] ?? banner['image'] ?? '';
                      final preview = SizedBox(
                        width: isCompact ? double.infinity : 120,
                        child: _buildBannerPreview(
                          imagePath,
                          height: isCompact ? 96 : 54,
                          fit: BoxFit.contain,
                          emptyText: 'No image',
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${i + 1}. Mid banner',
                              style: TextStyle(
                                color: AdminTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            preview,
                            const SizedBox(height: 8),
                            text,
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: actions,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Text(
                            '${i + 1}.',
                            style: TextStyle(
                              color: AdminTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          preview,
                          const SizedBox(width: 12),
                          Expanded(child: text),
                          const SizedBox(width: 12),
                          actions,
                        ],
                      );
                    },
                  ),
                );
              }),

              if (midBanners.isEmpty && !_midFormVisible)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "No mid banners. Click \"Add banner\" to add one.",
                    style: TextStyle(color: AdminTheme.textSecondary),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarPromoSection() {
    return Consumer<BannerProvider>(
      builder: (context, bp, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sidebar Promo Card (Flash_Sale card)",
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sidebarTitleController,
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AdminTheme.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sidebarSubtitleController,
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Subtitle',
                  labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AdminTheme.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sidebarButtonController,
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Button text',
                  labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AdminTheme.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await bp.saveSidebarPromo({
                    'title': _sidebarTitleController.text.trim().isEmpty
                        ? 'Flash_Sale'
                        : _sidebarTitleController.text.trim(),
                    'subtitle': _sidebarSubtitleController.text.trim().isEmpty
                        ? 'Up to 40% Off on Earbuds'
                        : _sidebarSubtitleController.text.trim(),
                    'buttonText': _sidebarButtonController.text.trim().isEmpty
                        ? 'VIEW ALL'
                        : _sidebarButtonController.text.trim(),
                  });
                  if (mounted) {
                    await bp.load(force: true);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sidebar promo saved.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: AdminTheme.textPrimary,
                ),
                child: const Text('Save Sidebar Promo'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Material(
        color: darkBg,
        child: SizedBox.expand(child: _buildContent()),
      );
    }
    return AdminScaffold(
      selected: AdminSidebarItem.banners,
      onItemSelected: (item) => _navigate(context, item),
      body: _buildContent(),
    );
  }
}


