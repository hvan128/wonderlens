import 'package:flutter/widgets.dart';

/// Observer toàn cục để các màn (vd camera) biết khi nào bị màn khác phủ lên
/// (`didPushNext`) hoặc được lộ lại (`didPopNext`) — dùng để nhả/mở lại camera.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
