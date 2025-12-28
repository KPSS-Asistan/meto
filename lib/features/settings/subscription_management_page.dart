import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kpss_2026/core/services/revenuecat_service.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';

/// Abonelik Yönetimi Sayfası
/// RevenueCat'in hazır Customer Center UI'sini gösterir
class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  State<SubscriptionManagementPage> createState() => _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState extends State<SubscriptionManagementPage> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionManagement();
  }

  Future<void> _loadSubscriptionManagement() async {
    try {
      setState(() => _isLoading = true);

      // RevenueCat Customer Center'ı aç
      final revenueCat = RevenueCatService();
      await revenueCat.showCustomerCenter(context);

      // Customer Center açıldıktan sonra sayfayı kapat
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      AppLogger.error('Abonelik yönetimi sayfası hatası:', e);
      setState(() {
        _isLoading = false;
        _error = 'Abonelik yönetimi şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Abonelik Yönetimi'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Abonelik yönetimi yükleniyor...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.circleAlert, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadSubscriptionManagement,
                child: const Text('Tekrar Dene'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    // Bu kısım normalde çalışmaz çünkü Customer Center açılır açılmaz pop() yapılır
    return const Center(
      child: Text('Abonelik yönetimi yükleniyor...'),
    );
  }
}
