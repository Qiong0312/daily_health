import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/health_models.dart';
import 'providers/health_provider.dart';
import 'screens/settings_view.dart';
import 'screens/summary_view.dart';
import 'screens/today_view.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

class BloomApp extends StatefulWidget {
  const BloomApp({super.key});

  @override
  State<BloomApp> createState() => _BloomAppState();
}

class _BloomAppState extends State<BloomApp> {
  AppTab _tab = AppTab.today;

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, provider, _) {
        if (!provider.ready) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(),
            home: Scaffold(
              body: Container(
                decoration: AppTheme.loadingGradient,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🌸', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text(
                      'Bloom',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.rose800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: Scaffold(
            body: Container(
              decoration: AppTheme.shellGradient,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Row(
                        children: [
                          const Text('🌸', style: TextStyle(fontSize: 26)),
                          const SizedBox(width: 8),
                          const Text(
                            'Bloom',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.rose800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),
                          if (_tab == AppTab.today && provider.isOnPeriod())
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.rose100,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.rose300),
                              ),
                              child: const Text(
                                'Period day',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.rose700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildBody()),
                    BottomNav(
                      activeTab: _tab,
                      onTabChanged: (t) => setState(() => _tab = t),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case AppTab.today:
        return const TodayView();
      case AppTab.summary:
        return const SummaryView();
      case AppTab.settings:
        return const SettingsView();
    }
  }
}
