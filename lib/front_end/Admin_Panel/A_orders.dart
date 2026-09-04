import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:electrocitybd1/front_end/utils/web_download.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:electrocitybd1/front_end/Provider/Orders_provider.dart';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_customers.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';
import 'package:electrocitybd1/config/app_colors.dart';

class AdminOrdersPage extends StatefulWidget {
  final bool embedded;

  const AdminOrdersPage({super.key, this.embedded = false});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String? filterStatus;
  bool showWeekly = false;
  bool _autoRefresh = false;
  Timer? _autoTimer;
  DateTime? _lastUpdated;
  static const int _refreshIntervalSeconds = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<OrdersProvider>();
      // Clear any cached user orders before loading admin orders
      provider.clearForLogout();
      await provider.refreshFromApi(admin: true);
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh(OrdersProvider ordersProvider) {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(
      const Duration(seconds: _refreshIntervalSeconds),
      (_) async {
        await ordersProvider.refreshFromApi(admin: true);
        if (!mounted) return;
        setState(() {
          _lastUpdated = DateTime.now();
        });
      },
    );
    setState(() {
      _autoRefresh = true;
      _lastUpdated = DateTime.now();
    });
  }

  void _stopAutoRefresh() {
    _autoTimer?.cancel();
    setState(() {
      _autoRefresh = false;
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  int _getGridCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) return 1; // Mobile: 1 column
    if (screenWidth < 1024) return 2; // Tablet: 2 columns
    if (screenWidth < 1400) return 3; // Desktop: 3 columns
    return 4; // Large desktop: 4 columns
  }

  Widget _buildOrdersContent() {
    return Consumer<OrdersProvider>(
      builder: (context, ordersProvider, _) {
        // Build filtered order list
        List<Map<String, String>> orders = ordersProvider.ordersNewestFirst
            .map((o) => o.toAdminRow())
            .toList();

        List<Map<String, String>> filteredOrders = List.from(orders);
        if (filterStatus != null) {
          filteredOrders = filteredOrders
              .where((o) => o['status'] == filterStatus)
              .toList();
        }
        if (showWeekly) {
          final weekAgoMillis = DateTime.now()
              .subtract(const Duration(days: 7))
              .millisecondsSinceEpoch;
          filteredOrders = filteredOrders.where((o) {
            final millis = int.tryParse(o['createdAtMillis'] ?? '');
            return millis == null || millis >= weekAgoMillis;
          }).toList();
        }

        return CustomScrollView(
          slivers: [
            // -- Top bar --
            SliverToBoxAdapter(child: _buildTopBar()),

            // -- Error banner --
            if (ordersProvider.error != null)
              SliverToBoxAdapter(
                child: Container(
                  color: const Color(0xFFFFF4E5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final message = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFB45309),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ordersProvider.error!,
                              style: const TextStyle(color: Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      );
                      final retry = TextButton(
                        onPressed: () =>
                            ordersProvider.refreshFromApi(admin: true),
                        child: const Text('Retry'),
                      );

                      if (constraints.maxWidth < 420) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            message,
                            Align(
                              alignment: Alignment.centerRight,
                              child: retry,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: message),
                          retry,
                        ],
                      );
                    },
                  ),
                ),
              ),

            // -- Loading spinner --
            if (ordersProvider.isLoading && ordersProvider.orders.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // -- Action buttons --
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          String csv =
                              "Order ID,Store,Method,Time Slot,Created,Status,Transaction ID,Total\n";
                          for (var o in filteredOrders) {
                            csv +=
                                "${o['orderCode'] ?? o['id'] ?? ''},${o['store'] ?? ''},${o['method'] ?? ''},${o['slot'] ?? ''},${o['created'] ?? ''},${o['status'] ?? ''},${o['transactionId'] ?? ''},${o['total'] ?? ''}\n";
                          }
                          if (kIsWeb) downloadCsvOnWeb(csv, 'orders.csv');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                kIsWeb
                                    ? "CSV downloaded!"
                                    : "Export is only available on web.",
                              ),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text("Export"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.grey300,
                          foregroundColor: AppColors.grey300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminTheme.border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButton<String?>(
                          value: filterStatus,
                          icon: const Icon(Icons.filter_list, size: 18),
                          underline: const SizedBox.shrink(),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    size: 16,
                                    color: Color(0xFFE0E0E0),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Filter",
                                    style: const TextStyle(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem<String?>(
                              value: "pending",
                              child: Text("Pending"),
                            ),
                            DropdownMenuItem<String?>(
                              value: "processing",
                              child: Text("Processing"),
                            ),
                            DropdownMenuItem<String?>(
                              value: "shipped",
                              child: Text("Shipped"),
                            ),
                            DropdownMenuItem<String?>(
                              value: "delivered",
                              child: Text("Delivered"),
                            ),
                            DropdownMenuItem<String?>(
                              value: "cancelled",
                              child: Text("Cancelled"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => filterStatus = value);
                          },
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => showWeekly = !showWeekly),
                        icon: Icon(
                          showWeekly
                              ? Icons.calendar_today
                              : Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        label: Text(showWeekly ? "Weekly (Active)" : "Weekly"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: showWeekly
                              ? Colors.blue.shade600
                              : const Color(0xFFEEEEEE),
                          foregroundColor: showWeekly
                              ? Colors.white
                              : const Color(0xFFEEEEEE),
                          elevation: showWeekly ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: showWeekly
                                ? BorderSide.none
                                : BorderSide(color: AdminTheme.border),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Auto Refresh",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                          Switch(
                            value: _autoRefresh,
                            onChanged: (v) {
                              if (v) {
                                _startAutoRefresh(ordersProvider);
                              } else {
                                _stopAutoRefresh();
                              }
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      if (_lastUpdated != null)
                        Text(
                          "Updated: ${_formatTime(_lastUpdated!)}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // -- Filter info --
              if (filterStatus != null || showWeekly)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    color: Colors.blue[50],
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final info = Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Active filters: ${filterStatus != null ? 'Status: $filterStatus' : ''}${filterStatus != null && showWeekly ? ', ' : ''}${showWeekly ? 'Last 7 days' : ''} (${filteredOrders.length} of ${orders.length} orders)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        );
                        final clear = TextButton(
                          onPressed: () => setState(() {
                            filterStatus = null;
                            showWeekly = false;
                          }),
                          child: const Text(
                            'Clear',
                            style: TextStyle(fontSize: 12),
                          ),
                        );

                        if (constraints.maxWidth < 420) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              info,
                              Align(
                                alignment: Alignment.centerRight,
                                child: clear,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: info),
                            clear,
                          ],
                        );
                      },
                    ),
                  ),
                ),

              // -- Empty state --
              if (filteredOrders.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AdminTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            orders.isEmpty
                                ? 'No orders yet.'
                                : 'No orders match the filter.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // -- Order List View (Table Style) --
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Header Row
                          Container(
                            color: Color(0xFFE0E0E0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Order ID',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE0E0E0),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 130,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Customer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE0E0E0),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Total',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE0E0E0),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Payment',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE0E0E0),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 140,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Date',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE0E0E0),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE0E0E0),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Action',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE0E0E0),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Data Rows
                          ...filteredOrders.asMap().entries.map((entry) {
                            final index = entry.key;
                            final order = entry.value;
                            final allOrders = ordersProvider.ordersNewestFirst;
                            final fullOrder = allOrders.firstWhere(
                              (o) => o.orderId == order["id"],
                              orElse: () => allOrders.isNotEmpty
                                  ? allOrders.first
                                  : PlacedOrder(
                                      orderId: order["id"] ?? '',
                                      transactionId:
                                          order["transactionId"] ?? '',
                                      paymentMethod: order["method"] ?? '',
                                      total:
                                          double.tryParse(
                                            order["total"] ?? '0',
                                          ) ??
                                          0,
                                      createdAt: order["created"] ?? '',
                                      status: order["status"] ?? '',
                                    ),
                            );

                            return _buildListTableRow(
                              context,
                              order,
                              fullOrder,
                              ordersProvider,
                              isAlternate: index.isEven,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    Map<String, String> order,
    PlacedOrder fullOrder,
    OrdersProvider ordersProvider,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () =>
            _showOrderDetailsDialog(context, fullOrder, ordersProvider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.black87],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Order ID + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order["orderCode"] ?? order["id"]!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusChip(order["status"]!),
                ],
              ),
              const SizedBox(height: 12),

              // Store & Method
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Store",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE0E0E0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order["store"] ?? "?",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Method",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE0E0E0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order["method"] ?? "?",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Time Slot & Created Date
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Slot",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE0E0E0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order["slot"] ?? "?",
                          style: TextStyle(
                            fontSize: 12,
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Created",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE0E0E0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order["created"] ?? "?",
                          style: TextStyle(
                            fontSize: 12,
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Transaction ID & Total
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Txn ID",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE0E0E0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order["transactionId"]?.isNotEmpty == true
                              ? order["transactionId"]!
                              : "?",
                          style: TextStyle(
                            fontSize: 12,
                            color: AdminTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE0E0E0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "?${order["total"] ?? "0"}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Update Order Status",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...[
                                  "pending",
                                  "processing",
                                  "shipped",
                                  "delivered",
                                  "cancelled",
                                ]
                                .map(
                                  (status) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          await ordersProvider
                                              .updateOrderStatus(
                                                order["id"]!,
                                                status,
                                              );
                                          if (!context.mounted) return;
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Order updated to $status",
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: $e"),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          40,
                                        ),
                                      ),
                                      child: Text(
                                        "Mark as ${status[0].toUpperCase()}${status.substring(1)}",
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text("Update Status"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTableRow(
    BuildContext context,
    Map<String, String> order,
    PlacedOrder fullOrder,
    OrdersProvider ordersProvider, {
    required bool isAlternate,
  }) {
    return Container(
      color: isAlternate ? Colors.black87 : Colors.white,
      child: InkWell(
        onTap: () =>
            _showOrderDetailsDialog(context, fullOrder, ordersProvider),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  order["orderCode"] ?? order["id"] ?? '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.green,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "${fullOrder.customerName ?? 'N/A'} ${fullOrder.customerLastName ?? ''}"
                      .trim(),
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "?${order["total"] ?? '0'}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 110,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  order["method"] ?? "?",
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  order["created"] ?? "?",
                  style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _statusChip(order["status"] ?? "pending"),
              ),
            ),
            SizedBox(
              width: 120,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: PopupMenuButton<String>(
                  tooltip: "Update status",
                  onSelected: (value) async {
                    try {
                      await ordersProvider.updateOrderStatus(
                        order["id"]!,
                        value,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Order #${order["id"]} updated to $value",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: "pending", child: Text("Pending")),
                    PopupMenuItem(
                      value: "processing",
                      child: Text("Processing"),
                    ),
                    PopupMenuItem(value: "shipped", child: Text("Shipped")),
                    PopupMenuItem(value: "delivered", child: Text("Delivered")),
                    PopupMenuItem(value: "cancelled", child: Text("Cancelled")),
                  ],
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileRow(Map<String, String> order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order["orderCode"] ?? order["id"]!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              _statusChip(order["status"]!),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "${order["store"]} ? ${order["method"]}",
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            "${order["created"]}",
            style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
          ),
          if (order["transactionId"]?.isNotEmpty == true)
            Text(
              "Txn: ${order["transactionId"]}",
              style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopRow(
    Map<String, String> order,
    OrdersProvider ordersProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                order["orderCode"] ?? order["id"]!,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(order["store"]!, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(order["method"]!, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(order["slot"]!, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Date: ${order["created"]}",
              style: const TextStyle(fontSize: 13, color: Color(0xFFE0E0E0)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              order["transactionId"]?.isNotEmpty == true
                  ? order["transactionId"]!
                  : "?",
              style: const TextStyle(fontSize: 13, color: Color(0xFFE0E0E0)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _statusChip(order["status"]!),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: "Update status",
                  onSelected: (value) async {
                    final id = int.tryParse(order["id"] ?? "");
                    if (id == null) return;
                    try {
                      await ordersProvider.updateOrderStatus(
                        order["id"]!,
                        value,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Order #${order["id"]} updated to $value",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: "pending",
                      child: Text("Mark as Pending"),
                    ),
                    PopupMenuItem(
                      value: "processing",
                      child: Text("Mark as Processing"),
                    ),
                    PopupMenuItem(
                      value: "shipped",
                      child: Text("Mark as Shipped"),
                    ),
                    PopupMenuItem(
                      value: "delivered",
                      child: Text("Mark as Delivered"),
                    ),
                    PopupMenuItem(
                      value: "cancelled",
                      child: Text("Mark as Cancelled"),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AdminTheme.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Container(
        color: const Color(0xFFF7F8FD),
        child: _buildOrdersContent(),
      );
    }
    return AdminScaffold(
      selected: AdminSidebarItem.orders,
      onItemSelected: (item) {
        if (item == AdminSidebarItem.orders) return;
        AdminNav.go(context, item);
      },
      body: _buildOrdersContent(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(children: [Spacer()]),
    );
  }

  void _showOrderDetailsDialog(
    BuildContext context,
    PlacedOrder order,
    OrdersProvider ordersProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width > 640
              ? 600
              : MediaQuery.of(context).size.width * 0.95,
          constraints: const BoxConstraints(maxHeight: 700),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AdminTheme.textSecondary, width: 1),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: const Color(0xFFE0E0E0),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order Details",
                            style: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Order ID: ${order.orderId}",
                            style: const TextStyle(
                              color: AdminTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AdminTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Code
                      _buildDetailCard(
                        icon: Icons.qr_code,
                        title: "Order Code",
                        content:
                            order.toAdminRow()['orderCode'] ?? order.orderId,
                        color: Color(0xFFE0E0E0),
                      ),
                      const SizedBox(height: 16),
                      // User Information Section
                      Text(
                        "Customer Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        icon: Icons.person,
                        title: "Customer Name",
                        content:
                            "${order.customerName ?? 'Not provided'}${order.customerLastName != null && order.customerLastName!.isNotEmpty ? ' ${order.customerLastName}' : ''}",
                        color: AdminTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        icon: Icons.email,
                        title: "Email Address",
                        content: order.customerEmail ?? "Not provided",
                        color: AdminTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        icon: Icons.phone,
                        title: "Phone Number",
                        content: order.customerPhone ?? "Not provided",
                        color: AdminTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        icon: Icons.home,
                        title: "User Address",
                        content: order.customerAddress ?? "Not provided",
                        color: AdminTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      if (order.customerGender != null &&
                          order.customerGender!.isNotEmpty)
                        _buildDetailCard(
                          icon: order.customerGender?.toLowerCase() == 'male'
                              ? Icons.male
                              : order.customerGender?.toLowerCase() == 'female'
                              ? Icons.female
                              : Icons.person_outline,
                          title: "Gender",
                          content: order.customerGender!,
                          color: Color(0xFFE0E0E0),
                        ),
                      if (order.customerGender != null &&
                          order.customerGender!.isNotEmpty)
                        const SizedBox(height: 12),
                      if (order.customerRole != null &&
                          order.customerRole!.isNotEmpty)
                        _buildDetailCard(
                          icon: Icons.badge,
                          title: "User Role",
                          content: order.customerRole!.toUpperCase(),
                          color: Color(0xFFE0E0E0),
                        ),
                      if (order.customerRole != null &&
                          order.customerRole!.isNotEmpty)
                        const SizedBox(height: 16),
                      // Delivery Address (if different from user address)
                      if (order.shippingAddress != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Delivery Address",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailCard(
                              icon: Icons.local_shipping,
                              title: "Shipping Address",
                              content: _formatAddress(order.shippingAddress!),
                              color: Color(0xFFE0E0E0),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      // Payment Information Section
                      const Text(
                        "Payment Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        icon: Icons.payment,
                        title: "Payment Method",
                        content: order.paymentMethod,
                        color: AdminTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        icon: Icons.receipt,
                        title: "Transaction ID",
                        content: order.transactionId.isNotEmpty
                            ? order.transactionId
                            : "Not available",
                        color: Color(0xFFE0E0E0),
                      ),
                      const SizedBox(height: 16),
                      // Order Information Section
                      const Text(
                        "Order Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        icon: Icons.access_time,
                        title: "Order Placed Time",
                        content: order.createdAt,
                        color: AdminTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        icon: order.getStatusIcon(),
                        title: "Order Status",
                        content: order.status.toUpperCase(),
                        color: AdminTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      if (order.estimatedDelivery != null &&
                          order.estimatedDelivery!.isNotEmpty)
                        _buildDetailCard(
                          icon: Icons.local_shipping_outlined,
                          title: "Estimated Delivery",
                          content: order.estimatedDelivery!,
                          color: Color(0xFFE0E0E0),
                        ),
                      if (order.estimatedDelivery != null &&
                          order.estimatedDelivery!.isNotEmpty)
                        const SizedBox(height: 12),
                      _buildDetailCard(
                        icon: Icons.receipt_long,
                        title: "Subtotal",
                        content:
                            "?${order.effectiveSubtotal.toStringAsFixed(2)}",
                        color: AdminTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        icon: Icons.local_shipping_outlined,
                        title: order.deliveryLabel,
                        content:
                            "?${order.effectiveDeliveryCharge.toStringAsFixed(2)}",
                        color: Color(0xFFE0E0E0),
                      ),
                      if (order.couponDiscount > 0) ...[
                        const SizedBox(height: 12),
                        _buildDetailCard(
                          icon: Icons.discount_outlined,
                          title: "Discount",
                          content:
                              "-?${order.couponDiscount.toStringAsFixed(2)}",
                          color: Color(0xFFE0E0E0),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        icon: Icons.attach_money,
                        title: "Grand Total",
                        content: "?${order.total.toStringAsFixed(2)}",
                        color: Color(0xFFE0E0E0),
                      ),
                      const SizedBox(height: 24),
                      // Order Items
                      const Text(
                        "Order Items",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (order.items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              "No items information available",
                              style: TextStyle(color: AppColors.grey300),
                            ),
                          ),
                        )
                      else
                        ...order.items.map((item) => _buildOrderItem(item)),
                    ],
                  ),
                ),
              ),
              // Footer Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: _buildOrderDialogActions(context, order, ordersProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDialogActions(
    BuildContext context,
    PlacedOrder order,
    OrdersProvider ordersProvider,
  ) {
    final actions = [
      _orderActionButton(
        label: 'Download Memo',
        icon: Icons.receipt_long,
        background: Colors.green[700]!,
        foreground: Colors.white,
        onPressed: () => _downloadOrderMemo(context, order),
      ),
      _orderActionButton(
        label: 'Request Delivery',
        icon: Icons.local_shipping_outlined,
        background: const Color(0xFF7C3AED),
        foreground: Colors.black,
        onPressed: () =>
            _showDeliveryRequestDialog(context, order, ordersProvider),
      ),
      _orderActionButton(
        label: 'Update Status',
        icon: Icons.edit,
        background: Colors.blue[600]!,
        foreground: Colors.white,
        onPressed: () =>
            _handleUpdateOrderStatus(context, order, ordersProvider),
      ),
      _orderActionButton(
        label: 'Delete Order',
        icon: Icons.delete_forever,
        background: Colors.red[600]!,
        foreground: Colors.white,
        onPressed: () => _handleDeleteOrder(context, order, ordersProvider),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final spacing = 10.0;
        final buttonWidth = isCompact
            ? ((constraints.maxWidth - spacing) / 2).clamp(120.0, 220.0)
            : ((constraints.maxWidth - spacing * 3) / 4).clamp(120.0, 180.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: actions
                  .map((button) => SizedBox(width: buttonWidth, child: button))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _orderActionButton({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        minimumSize: const Size(0, 46),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Future<void> _handleDeleteOrder(
    BuildContext context,
    PlacedOrder order,
    OrdersProvider ordersProvider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Order"),
        content: Text(
          "Are you sure you want to delete order #${order.orderId}?\n\n"
          "This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: AdminTheme.textPrimary,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await ordersProvider.deleteOrder(order.orderId);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete order: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleUpdateOrderStatus(
    BuildContext context,
    PlacedOrder order,
    OrdersProvider ordersProvider,
  ) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Order Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Pending"),
              onTap: () => Navigator.pop(context, "pending"),
            ),
            ListTile(
              title: const Text("Processing"),
              onTap: () => Navigator.pop(context, "processing"),
            ),
            ListTile(
              title: const Text("Shipped"),
              onTap: () => Navigator.pop(context, "shipped"),
            ),
            ListTile(
              title: const Text("Delivered"),
              onTap: () => Navigator.pop(context, "delivered"),
            ),
            ListTile(
              title: const Text("Cancelled"),
              onTap: () => Navigator.pop(context, "cancelled"),
            ),
          ],
        ),
      ),
    );
    if (newStatus == null) return;
    try {
      await ordersProvider.updateOrderStatus(order.orderId, newStatus);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order status updated to $newStatus"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.textSecondary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AdminTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final name =
        item['product_name']?.toString() ??
        item['name']?.toString() ??
        'Unknown Item';
    final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    // price_at_purchase is the canonical field from the DB; fall back to price/unit_price
    final unitPrice =
        double.tryParse(
          (item['price_at_purchase'] ?? item['price'] ?? item['unit_price'])
                  ?.toString() ??
              '0',
        ) ??
        0.0;
    final lineTotal = unitPrice * qty;
    final imageUrl =
        item['image_url']?.toString() ??
        item['product_image']?.toString() ??
        '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTheme.textPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 50,
              height: 50,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl.startsWith('http')
                          ? imageUrl
                          : '${_apiBase()}/$imageUrl'
                                .replaceAll('//', '/')
                                .replaceAll(':/', '://'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Color(0xFFE0E0E0),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                    )
                  : Container(
                      color: Color(0xFFE0E0E0),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Qty: $qty ? ?${unitPrice.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFE0E0E0),
                  ),
                ),
              ],
            ),
          ),
          Text(
            "?${lineTotal.toStringAsFixed(0)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadOrderMemo(BuildContext context, PlacedOrder order) {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memo download is available on web only.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final orderCode = _memoOrderCode(order);
    final html = _buildOrderMemoHtml(order);
    downloadTextOnWeb(
      html,
      'order-memo-$orderCode.html',
      mimeType: 'text/html;charset=utf-8',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Memo downloaded for $orderCode'),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  Future<void> _showDeliveryRequestDialog(
    BuildContext context,
    PlacedOrder order,
    OrdersProvider ordersProvider,
  ) async {
    final providers = await _loadEnabledDeliveryProviders();
    if (!context.mounted) return;

    if (providers.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delivery setup needed'),
          content: const Text(
            'No enabled delivery provider found. Enable Pathao, REDX, Steadfast, or another courier from admin Delivery settings first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    var selectedProvider = providers.first;
    var selectedMode = _deliveryModes(selectedProvider).first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Request Delivery'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order: ${_memoOrderCode(order)}'),
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selectedProvider,
                  decoration: const InputDecoration(labelText: 'Provider'),
                  items: providers
                      .map(
                        (provider) => DropdownMenuItem(
                          value: provider,
                          child: Text(_deliveryProviderName(provider)),
                        ),
                      )
                      .toList(),
                  onChanged: (provider) {
                    if (provider == null) return;
                    setDialogState(() {
                      selectedProvider = provider;
                      selectedMode = _deliveryModes(provider).first;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMode,
                  decoration: const InputDecoration(labelText: 'Service mode'),
                  items: _deliveryModes(selectedProvider)
                      .map(
                        (mode) =>
                            DropdownMenuItem(value: mode, child: Text(mode)),
                      )
                      .toList(),
                  onChanged: (mode) {
                    if (mode != null) setDialogState(() => selectedMode = mode);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  _deliveryApiReady(selectedProvider)
                      ? 'API credentials are saved. Confirming will mark the order as shipped; live courier booking still depends on backend API activation.'
                      : 'Manual booking mode. Confirming will mark the order as shipped for delivery follow-up.',
                  style: const TextStyle(color: Color(0xFFE0E0E0)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check),
              label: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ordersProvider.updateOrderStatus(order.orderId, 'shipped');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delivery requested with ${_deliveryProviderName(selectedProvider)} ($selectedMode).',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request delivery: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadEnabledDeliveryProviders() async {
    try {
      final response = await ApiService.getSiteSetting(
        'delivery_provider_settings',
      );
      final data = response['data'];
      final raw =
          response['setting_value'] ??
          response['value'] ??
          (data is Map ? data['setting_value'] ?? data['value'] : null);
      if (raw == null || raw.toString().trim().isEmpty) return [];
      final decoded = jsonDecode(raw.toString());
      if (decoded is! Map || decoded['providers'] is! List) return [];
      return (decoded['providers'] as List)
          .whereType<Map>()
          .map((provider) => Map<String, dynamic>.from(provider))
          .where((provider) => provider['enabled'] == true)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _deliveryProviderName(Map<String, dynamic> provider) {
    return provider['name']?.toString() ?? 'Delivery Provider';
  }

  List<String> _deliveryModes(Map<String, dynamic> provider) {
    final modes = provider['serviceModes'];
    if (modes is List && modes.isNotEmpty) {
      return modes.map((mode) => mode.toString()).toList();
    }
    return const ['Home delivery'];
  }

  bool _deliveryApiReady(Map<String, dynamic> provider) {
    return provider['apiMode'] != 'manual' &&
        (provider['merchantId']?.toString().isNotEmpty ?? false) &&
        (provider['apiKey']?.toString().isNotEmpty ?? false);
  }

  String _buildOrderMemoHtml(PlacedOrder order) {
    final escape = const HtmlEscape().convert;
    final orderCode = _memoOrderCode(order);
    final customerName = _memoCustomerName(order);
    final shippingAddress = order.shippingAddress == null
        ? (order.customerAddress ?? 'Not provided')
        : _formatAddress(order.shippingAddress!);
    final generatedAt = DateTime.now().toIso8601String().split('.').first;
    final subtotal = order.effectiveSubtotal;
    final delivery = order.effectiveDeliveryCharge;
    final discount = order.couponDiscount;
    final deliveryLabel = order.deliveryLabel;
    final itemsHtml = order.items.isEmpty
        ? '<tr><td colspan="5" class="empty">No item information available</td></tr>'
        : order.items.map((item) {
            final name = _memoItemName(item);
            final sku =
                item['sku']?.toString() ?? item['product_id']?.toString() ?? '';
            final qty = _memoItemQuantity(item);
            final unitPrice = _memoItemPrice(item);
            final lineTotal = qty * unitPrice;
            return '''
              <tr>
                <td>
                  <strong>${escape(name)}</strong>
                  ${sku.isEmpty ? '' : '<span>SKU/Product: ${escape(sku)}</span>'}
                </td>
                <td>${escape(qty.toString())}</td>
                <td>BDT ${unitPrice.toStringAsFixed(2)}</td>
                <td>BDT ${lineTotal.toStringAsFixed(2)}</td>
              </tr>
            ''';
          }).join();

    return '''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Order Memo $orderCode</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: #f3f5f9;
      color: #111827;
      font-family: Inter, Arial, Helvetica, sans-serif;
      line-height: 1.45;
    }
    .memo {
      width: min(920px, calc(100% - 32px));
      margin: 24px auto;
      background: #ffffff;
      border: 1px solid #e5e7eb;
      border-radius: 18px;
      overflow: hidden;
      box-shadow: 0 18px 50px rgba(15, 23, 42, 0.12);
    }
    .top {
      display: flex;
      justify-content: space-between;
      gap: 24px;
      padding: 32px;
      color: #fff;
      background: linear-gradient(135deg, #111827, #1f2937 58%, #f59e0b);
    }
    h1, h2, h3, p { margin: 0; }
    .brand h1 { font-size: 30px; letter-spacing: 0; }
    .brand p, .meta p { color: rgba(255,255,255,0.78); margin-top: 6px; }
    .badge {
      display: inline-block;
      margin-top: 14px;
      padding: 7px 12px;
      border-radius: 999px;
      color: #111827;
      background: #fbbf24;
      font-weight: 700;
      font-size: 12px;
      text-transform: uppercase;
    }
    .meta { text-align: right; min-width: 220px; }
    .meta h2 { font-size: 20px; }
    .section { padding: 28px 32px; border-bottom: 1px solid #eef0f4; }
    .grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 18px; }
    .box {
      border: 1px solid #e5e7eb;
      border-radius: 14px;
      padding: 16px;
      background: #fbfcfe;
    }
    .box h3 { font-size: 13px; color: #6b7280; text-transform: uppercase; margin-bottom: 10px; }
    .box p { margin-top: 5px; }
    table { width: 100%; border-collapse: collapse; }
    th {
      text-align: left;
      padding: 12px 10px;
      color: #6b7280;
      font-size: 12px;
      text-transform: uppercase;
      border-bottom: 1px solid #e5e7eb;
    }
    td { padding: 14px 10px; border-bottom: 1px solid #eef0f4; vertical-align: top; }
    td span { display: block; color: #6b7280; font-size: 12px; margin-top: 4px; }
    td:nth-child(2), td:nth-child(3), td:nth-child(4),
    th:nth-child(2), th:nth-child(3), th:nth-child(4) { text-align: right; }
    .empty { text-align: center; color: #6b7280; }
    .summary {
      display: flex;
      justify-content: flex-end;
      padding: 24px 32px 32px;
    }
    .total {
      width: min(360px, 100%);
      border: 1px solid #e5e7eb;
      border-radius: 14px;
      padding: 18px;
      background: #111827;
      color: #ffffff;
    }
    .total-row {
      display: flex;
      justify-content: space-between;
      gap: 16px;
      padding: 6px 0;
    }
    .total-row strong { font-size: 22px; color: #fbbf24; }
    .note {
      padding: 18px 32px 30px;
      color: #6b7280;
      font-size: 12px;
    }
    @media print {
      body { background: #fff; }
      .memo { width: 100%; margin: 0; border: 0; box-shadow: none; border-radius: 0; }
    }
    @media (max-width: 700px) {
      .top, .grid { display: block; }
      .meta { text-align: left; margin-top: 18px; }
      .box { margin-bottom: 12px; }
    }
  </style>
</head>
<body>
  <main class="memo">
    <section class="top">
      <div class="brand">
        <h1>ElectroZoneBD</h1>
        <p>Order Receipt / Memo</p>
        <span class="badge">${escape(order.status)}</span>
      </div>
      <div class="meta">
        <h2>${escape(orderCode)}</h2>
        <p>Order date: ${escape(order.createdAt)}</p>
        <p>Generated: ${escape(generatedAt)}</p>
      </div>
    </section>

    <section class="section grid">
      <div class="box">
        <h3>Customer</h3>
        <p><strong>${escape(customerName)}</strong></p>
        <p>${escape(order.customerPhone ?? 'Phone not provided')}</p>
        <p>${escape(order.customerEmail ?? 'Email not provided')}</p>
      </div>
      <div class="box">
        <h3>Delivery Address</h3>
        <p>${escape(shippingAddress)}</p>
      </div>
      <div class="box">
        <h3>Payment</h3>
        <p><strong>${escape(order.paymentMethod)}</strong></p>
        <p>Transaction: ${escape(order.transactionId.isEmpty ? 'N/A' : order.transactionId)}</p>
      </div>
      <div class="box">
        <h3>Delivery</h3>
        <p>Status: ${escape(order.status.toUpperCase())}</p>
        <p>Estimate: ${escape(order.estimatedDelivery ?? 'Not provided')}</p>
      </div>
    </section>

    <section class="section">
      <table>
        <thead>
          <tr>
            <th>Item</th>
            <th>Qty</th>
            <th>Unit</th>
            <th>Total</th>
          </tr>
        </thead>
        <tbody>$itemsHtml</tbody>
      </table>
    </section>

    <section class="summary">
      <div class="total">
        <div class="total-row"><span>Subtotal</span><span>BDT ${subtotal.toStringAsFixed(2)}</span></div>
        <div class="total-row"><span>${escape(deliveryLabel)}</span><span>BDT ${delivery.toStringAsFixed(2)}</span></div>
        ${discount > 0 ? '<div class="total-row"><span>Discount</span><span>-BDT ${discount.toStringAsFixed(2)}</span></div>' : ''}
        <div class="total-row"><span>Grand Total</span><strong>BDT ${order.total.toStringAsFixed(2)}</strong></div>
      </div>
    </section>
    <p class="note">This memo was generated from the ElectroZoneBD Admin_Panel. Please keep it with the delivery parcel and customer order record.</p>
  </main>
</body>
</html>
''';
  }

  String _memoOrderCode(PlacedOrder order) {
    final id = order.orderId;
    if (id.startsWith('EC-')) return id;
    if (int.tryParse(id) == null) return id;
    final date = DateTime.fromMillisecondsSinceEpoch(order.createdAtMillis);
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'EC-$y$m$d-$id';
  }

  String _memoCustomerName(PlacedOrder order) {
    final parts = [
      order.customerName,
      order.customerLastName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
    return parts.isEmpty ? 'Customer' : parts;
  }

  String _memoItemName(Map<String, dynamic> item) {
    return item['product_name']?.toString() ??
        item['name']?.toString() ??
        item['title']?.toString() ??
        'Unknown Item';
  }

  int _memoItemQuantity(Map<String, dynamic> item) {
    return int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
  }

  double _memoItemPrice(Map<String, dynamic> item) {
    return double.tryParse(
          (item['price_at_purchase'] ?? item['price'] ?? item['unit_price'])
                  ?.toString() ??
              '0',
        ) ??
        0;
  }

  String _apiBase() {
    // Returns the backend base URL for resolving relative image paths
    try {
      return ApiService.overrideBaseUrl ?? 'https://electrozonebd.com';
    } catch (_) {
      return 'https://electrozonebd.com';
    }
  }

  String _formatAddress(Map<String, dynamic> address) {
    // If it's a simple address string
    if (address.containsKey('address') && address.length == 1) {
      return address['address'].toString();
    }

    // Otherwise format as structured address
    final parts = <String>[];
    if (address['street'] != null && address['street'].toString().isNotEmpty) {
      parts.add(address['street'].toString());
    }
    if (address['city'] != null && address['city'].toString().isNotEmpty) {
      parts.add(address['city'].toString());
    }
    if (address['state'] != null && address['state'].toString().isNotEmpty) {
      parts.add(address['state'].toString());
    }
    if (address['zip'] != null && address['zip'].toString().isNotEmpty) {
      parts.add(address['zip'].toString());
    }
    if (address['country'] != null &&
        address['country'].toString().isNotEmpty) {
      parts.add(address['country'].toString());
    }

    return parts.isEmpty ? "Not provided" : parts.join(", ");
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case "pending":
        color = Colors.orange;
        break;
      case "processing":
        color = Colors.blue;
        break;
      case "shipped":
        color = Colors.purple;
        break;
      case "delivered":
        color = Colors.green;
        break;
      case "cancelled":
        color = Colors.red;
        break;
      default:
        color = Colors.black87;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  final int flex;
  const _TableHeader(this.label, {this.flex = 1, super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFE0E0E0),
          fontSize: 13,
        ),
      ),
    );
  }
}
