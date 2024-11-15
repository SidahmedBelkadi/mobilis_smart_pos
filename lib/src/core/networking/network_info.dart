import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl({required this.connectivity});
  @override
  Future<bool> get isConnected async => await _checkConnectivity(connectivity: connectivity);
}

_checkConnectivity({required Connectivity connectivity}) async {
  final List<ConnectivityResult> connectivityResult = await (connectivity.checkConnectivity());
  if (connectivityResult.contains(ConnectivityResult.mobile) ||
      connectivityResult.contains(ConnectivityResult.wifi)) {
    return Future.value(true);
  } else {
    return Future.value(false);
  }
}
