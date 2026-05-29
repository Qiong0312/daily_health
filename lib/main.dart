import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/health_provider.dart';
import 'widget/widget_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => HealthProvider()..init(),
      child: const _BloomAppWithWidgetSync(),
    ),
  );
}

class _BloomAppWithWidgetSync extends StatefulWidget {
  const _BloomAppWithWidgetSync();

  @override
  State<_BloomAppWithWidgetSync> createState() => _BloomAppWithWidgetSyncState();
}

class _BloomAppWithWidgetSyncState extends State<_BloomAppWithWidgetSync>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetBridge.installSyncListener(() async {
      if (!mounted) return;
      final provider = context.read<HealthProvider>();
      if (!provider.ready) return;
      await provider.syncFromWidget();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<HealthProvider>();
      if (!provider.ready) return;
      provider.syncFromWidget();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const BloomApp();
  }
}
