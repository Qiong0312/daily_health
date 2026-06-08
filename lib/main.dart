import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/health_provider.dart';
import 'widget/widget_bridge.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Uncaught async error: $error\n$stack');
        return true;
      };

      runApp(
        ChangeNotifierProvider(
          create: (_) => HealthProvider()..init(),
          child: const _BloomAppWithWidgetSync(),
        ),
      );
    },
    (error, stack) => debugPrint('Zone error: $error\n$stack'),
  );
}

class _BloomAppWithWidgetSync extends StatefulWidget {
  const _BloomAppWithWidgetSync();

  @override
  State<_BloomAppWithWidgetSync> createState() => _BloomAppWithWidgetSyncState();
}

class _BloomAppWithWidgetSyncState extends State<_BloomAppWithWidgetSync>
    with WidgetsBindingObserver {
  Timer? _resumeSyncTimer;
  Timer? _darwinSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetBridge.installSyncListener(() async {
      _darwinSyncTimer?.cancel();
      _darwinSyncTimer = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        final provider = context.read<HealthProvider>();
        if (!provider.ready) return;
        unawaited(provider.syncFromWidget());
      });
    });
  }

  @override
  void dispose() {
    _resumeSyncTimer?.cancel();
    _darwinSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _resumeSyncTimer?.cancel();
    _resumeSyncTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final provider = context.read<HealthProvider>();
      if (!provider.ready) return;
      unawaited(provider.syncFromWidget());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const BloomApp();
  }
}
