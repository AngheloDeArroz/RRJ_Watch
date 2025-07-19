import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'trends_screen.dart';
import 'system_status_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    TrendsScreen(),
    SystemStatusScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    String title;
    switch (_selectedIndex) {
      case 0:
        title = 'RRJ Watch';
        break;
      case 1:
        title = 'RRJ Watch';
        break;
      case 2:
        title = 'RRJ Watch';
        break;
      default:
        title = 'RRJ Watch';
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/splash_logo_centered.png',
              height: 32,
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'SuperWater',
                  fontSize: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Color(0xFF006D77),
        elevation: 4,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/fishh.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          _pages[_selectedIndex],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF006D77),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFF83C5BE),
        unselectedItemColor: Color(0xFFBEE3DB),
        selectedLabelStyle: TextStyle(
          fontFamily: 'Lexend',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Lexend',
          fontWeight: FontWeight.w400,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.waves),
            label: 'Trends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.developer_board),
            label: 'System Status',
          ),
        ],
      ),
    );
  }
}
