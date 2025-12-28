import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';

/// 🌐 Connectivity Service
/// İnternet bağlantısı durumunu takip eder
/// 
/// Kullanım:
/// final connectivity = ConnectivityService();
/// await connectivity.initialize();
/// 
/// // Stream ile dinleme
/// connectivity.onConnectivityChanged.listen((isConnected) {
///   print('Connected: $isConnected');
/// });
/// 
/// // Anlık kontrol
/// final isOnline = await connectivity.isConnected;
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  final _connectivityController = StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  bool _isInitialized = false;

  /// Bağlantı durumu stream'i
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;
  
  /// Anlık bağlantı durumu
  bool get isConnectedSync => _isConnected;
  
  /// Async bağlantı durumu kontrolü
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  /// Servisi başlat
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // İlk durumu kontrol et
      final result = await _connectivity.checkConnectivity();
      _isConnected = _hasConnection(result);
      _connectivityController.add(_isConnected);
      
      // Değişiklikleri dinle
      _subscription = _connectivity.onConnectivityChanged.listen((result) {
        final connected = _hasConnection(result);
        
        if (_isConnected != connected) {
          _isConnected = connected;
          _connectivityController.add(_isConnected);
          
          if (connected) {
            AppLogger.info('🌐 İnternet bağlantısı kuruldu');
          } else {
            AppLogger.warning('📵 İnternet bağlantısı kesildi');
          }
        }
      });
      
      _isInitialized = true;
      AppLogger.info('✅ ConnectivityService initialized');
    } catch (e) {
      AppLogger.error('❌ ConnectivityService initialization failed', e);
    }
  }

  /// Bağlantı var mı kontrol et
  bool _hasConnection(List<ConnectivityResult> result) {
    return result.any((r) => 
      r == ConnectivityResult.wifi || 
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet
    );
  }

  /// Servisi temizle
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}

/// Connectivity durumunu gösteren widget
/// Bağlantı kesildiğinde otomatik olarak banner gösterir

class ConnectivityBanner extends StatelessWidget {
  final Widget child;
  
  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().onConnectivityChanged,
      initialData: ConnectivityService().isConnectedSync,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;
        
        return Column(
          children: [
            // Offline banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isConnected ? 0 : 32,
              color: Colors.red.shade700,
              child: isConnected 
                ? const SizedBox.shrink()
                : const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'İnternet bağlantısı yok',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
            // Main content
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
