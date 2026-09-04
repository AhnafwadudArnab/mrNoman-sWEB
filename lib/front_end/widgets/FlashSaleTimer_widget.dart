import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class FlashSaleTimer extends StatefulWidget {
  final VoidCallback? onExpired;

  const FlashSaleTimer({super.key, this.onExpired});

  @override
  State<FlashSaleTimer> createState() => _FlashSaleTimerState();
}

class _FlashSaleTimerState extends State<FlashSaleTimer> {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isLoading = true;
  bool _hasFlashSale = false;
  String _flashSaleTitle = '';

  @override
  void initState() {
    super.initState();
    _loadFlashSale();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadFlashSale() async {
    try {
      final response = await ApiService.get('/Flash_Sales?active=true');
      
      if (response != null && response['active'] == true) {
        final secondsRemaining = response['seconds_remaining'] ?? 0;
        final title = response['title'] ?? 'Flash_Sale';
        
        if (mounted) {
          setState(() {
            _secondsRemaining = secondsRemaining;
            _flashSaleTitle = title;
            _hasFlashSale = secondsRemaining > 0;
            _isLoading = false;
          });
          
          if (_hasFlashSale) {
            _startTimer();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _hasFlashSale = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasFlashSale = false;
          _isLoading = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      // Defer setState to avoid the mouse-tracker assertion on Flutter Web.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          timer.cancel();
          widget.onExpired?.call();
          setState(() {
            _hasFlashSale = false;
          });
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (!_hasFlashSale) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0x4DF44336),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.flash_on,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _flashSaleTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_secondsRemaining),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Compact version for product cards
class FlashSaleTimerCompact extends StatefulWidget {
  final int secondsRemaining;

  const FlashSaleTimerCompact({
    super.key,
    required this.secondsRemaining,
  });

  @override
  State<FlashSaleTimerCompact> createState() => _FlashSaleTimerCompactState();
}

class _FlashSaleTimerCompactState extends State<FlashSaleTimerCompact> {
  Timer? _timer;
  late int _secondsRemaining;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.secondsRemaining;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      // Defer setState to avoid the mouse-tracker assertion on Flutter Web.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsRemaining <= 0) {
      return const Text(
        'EXPIRED',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(_secondsRemaining),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}










