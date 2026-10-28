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
  Stream<bool> watchOnlineStatus() async* {
    // Emit the current state first.
    yield await isOnline();

    // Continue listening for network-interface changes.
    yield* _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  @override
  Future<bool> isOnline() async {
    try {
      return _hasConnection(await _connectivity.checkConnectivity());
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
