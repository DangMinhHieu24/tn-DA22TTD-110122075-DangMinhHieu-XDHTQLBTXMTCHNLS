import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import '../widgets/customer_app_bar.dart';
import '../widgets/reminder_banner.dart';
import '../widgets/service_progress_card.dart';
import '../widgets/technical_alert_card.dart';
import '../widgets/maintenance_history.dart';
import '../widgets/customer_bottom_nav.dart';

class CustomerDashboardPage extends StatelessWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const CustomerAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ReminderBanner(),
                    SizedBox(height: 20),
                    ServiceProgressCard(),
                    SizedBox(height: 20),
                    TechnicalAlertCard(),
                    SizedBox(height: 20),
                    MaintenanceHistory(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomerBottomNav(),
    );
  }
}
