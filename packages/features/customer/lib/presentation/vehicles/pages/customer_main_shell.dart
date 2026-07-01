import 'package:flutter/material.dart';
import 'my_vehicles_page.dart';
import '../../appointments/pages/appointments_page.dart';
import '../../account/pages/customer_account_page.dart';
import '../widgets/customer_bottom_nav.dart';
import '../../chat/widgets/chat_floating_bubble.dart';

class CustomerMainShell extends StatefulWidget {
  final int initialIndex;
  const CustomerMainShell({super.key, this.initialIndex = 0});

  @override
  State<CustomerMainShell> createState() => _CustomerMainShellState();
}

class _CustomerMainShellState extends State<CustomerMainShell> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    MyVehiclesPage(),
    AppointmentsPage(),
    CustomerAccountPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Preserve state of pages using IndexedStack
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),

          // Premium Floating Glassmorphic Bottom Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: CustomerBottomNav(
              selectedIndex: _currentIndex,
              onItemSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),

          // Persistent Chat Bubble
          const ChatFloatingBubble(),
        ],
      ),
    );
  }
}
