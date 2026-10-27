import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityService {
  Stream<bool> watchOnlineStatus();
  Future<bool> isOnline();
}

class DefaultConnectivityService implements ConnectivityService {
  final Connectivity _connectivity;

  DefaultConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  @override
  Stream<bool> watchOnlineStatus() {
    return _connectivity.onConnectivityChanged.map((results) {
      return _hasConnection(results);
    });
  }

  @override
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _hasConnection(results);
    } catch (_) {
      return false;
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );
  }
}
