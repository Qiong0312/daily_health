import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/health_models.dart';
import '../utils/date_utils.dart';
import 'widget_snapshot.dart';

const _channel = MethodChannel('com.dailyhealth/widget_bridge');

class WidgetBridge {
  static bool get isSupported => !kIsWeb && Platform.isIOS;

  /// Called when a widget intent writes data (`needsAppSync`) while the app may be open.
  static void installSyncListener(Future<void> Function() onSync) {
    if (!isSupported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetDataChanged') {
        await onSync();
      }
    });
  }

  static Future<void> exportSnapshot(AppData data) async {
    if (!isSupported) return;
    final snapshot = WidgetSnapshot.fromAppData(data);
    try {
      await _channel.invokeMethod<void>(
        'writeSnapshot',
        jsonEncode(snapshot.toJson()),
      );
    } catch (e, st) {
      debugPrint('WidgetBridge.exportSnapshot failed: $e\n$st');
    }
  }

  static Future<AppData> importIfNeeded(AppData data) async {
    if (!isSupported) return data;
    try {
      final raw = await _channel.invokeMethod<String>('readSnapshot');
      if (raw == null || raw.isEmpty) return data;

      final snapshot = WidgetSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (snapshot.dateKey != todayKey()) return data;
      if (!snapshot.needsAppSync) return data;

      final merged = WidgetSnapshot.mergeIntoAppData(data, snapshot);
      await exportSnapshot(merged);
      return merged;
    } catch (e, st) {
      debugPrint('WidgetBridge.importIfNeeded failed: $e\n$st');
      return data;
    }
  }
}
