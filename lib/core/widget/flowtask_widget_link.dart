abstract final class FlowTaskWidgetLink {
  static const homeRoute = '/today';
  static const newTaskRoute = '/task/new';
  static const scheme = 'flowtaskwidget';

  /// Maps widget links and startup `/` to valid internal FlowTask routes.
  /// Returns null for ordinary non-widget routes so go_router can handle them.
  static String? normalizeLocation(String? location) {
    if (location == null || location.trim().isEmpty || location == '/') {
      return homeRoute;
    }

    final uri = Uri.tryParse(location);
    if (uri == null || uri.scheme != scheme) {
      return null;
    }

    return routeForUri(uri);
  }

  /// Invalid widget-generated links always return the safe Today route.
  static String routeForUri(Uri? uri) {
    if (uri == null || uri.scheme != scheme) {
      return homeRoute;
    }

    switch (uri.host) {
      case 'today':
        return homeRoute;
      case 'new':
        return newTaskRoute;
      case 'task':
        final pathId = uri.pathSegments.length == 1
            ? uri.pathSegments.single
            : null;
        final taskId = pathId ?? uri.queryParameters['taskId'];
        if (!_isValidTaskId(taskId)) {
          return homeRoute;
        }
        return '/task/${Uri.encodeComponent(taskId!)}';
      default:
        return homeRoute;
    }
  }

  static bool _isValidTaskId(String? taskId) {
    if (taskId == null || taskId.isEmpty) {
      return false;
    }
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(taskId);
  }
}
