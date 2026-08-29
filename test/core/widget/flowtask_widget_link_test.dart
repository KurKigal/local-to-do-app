import 'package:flutter_test/flutter_test.dart';
import 'package:flowtask/core/widget/flowtask_widget_link.dart';

void main() {
  const taskId = '123e4567-e89b-12d3-a456-426614174000';

  test('normal startup locations use Today safely', () {
    expect(FlowTaskWidgetLink.normalizeLocation('/today'), isNull);
    expect(FlowTaskWidgetLink.normalizeLocation('/'), '/today');
    expect(FlowTaskWidgetLink.normalizeLocation(null), '/today');
    expect(FlowTaskWidgetLink.normalizeLocation(''), '/today');
  });

  test('maps Today and New links with or without trailing slash', () {
    expect(
      FlowTaskWidgetLink.normalizeLocation('flowtaskwidget://today'),
      '/today',
    );
    expect(
      FlowTaskWidgetLink.normalizeLocation('flowtaskwidget://today/'),
      '/today',
    );
    expect(
      FlowTaskWidgetLink.normalizeLocation('flowtaskwidget://new'),
      '/task/new',
    );
    expect(
      FlowTaskWidgetLink.normalizeLocation('flowtaskwidget://new/'),
      '/task/new',
    );
  });

  test('maps valid task path and legacy query links', () {
    expect(
      FlowTaskWidgetLink.normalizeLocation('flowtaskwidget://task/$taskId'),
      '/task/$taskId',
    );
    expect(
      FlowTaskWidgetLink.normalizeLocation(
        'flowtaskwidget://task?taskId=$taskId',
      ),
      '/task/$taskId',
    );
  });

  test('invalid widget links fall back to Today', () {
    for (final location in [
      'flowtaskwidget://task/not-an-id',
      'flowtaskwidget://task/',
      'flowtaskwidget://unknown/',
      'flowtaskwidget:malformed',
    ]) {
      expect(FlowTaskWidgetLink.normalizeLocation(location), '/today');
    }
  });
}
