import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService() {
    _sub = Connectivity().onConnectivityChanged.listen((_) {
      _controller.add(null);
    });
  }

  late final StreamSubscription _sub;
  final _controller = StreamController<void>.broadcast();

  Stream<void> get changes => _controller.stream;

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}
