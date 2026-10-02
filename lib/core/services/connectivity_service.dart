import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

@riverpod
class ConnectivityNotifier extends _$ConnectivityNotifier {
  @override
  Stream<bool> build() async* {
    final connectivity = Connectivity();
    
    // Check initial
    final results = await connectivity.checkConnectivity();
    yield _isConnected(results);

    // Listen to changes
    await for (final results in connectivity.onConnectivityChanged) {
      yield _isConnected(results);
    }
  }

  bool _isConnected(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }
}
