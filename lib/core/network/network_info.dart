import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction for checking network connectivity.
/// Allows fail-fast behavior when offline — showing a "no connection" state
/// immediately is better UX than waiting for a timeout.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl({required this.connectivity});

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
