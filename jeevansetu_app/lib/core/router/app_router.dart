import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/permissions_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/emergency/presentation/screens/accident_alert_screen.dart';
import '../../features/emergency/presentation/screens/severity_result_screen.dart';
import '../../features/emergency/presentation/screens/emergency_contacts_screen.dart';
import '../../features/tracking/presentation/screens/live_tracking_screen.dart';
import '../../features/hospital/presentation/screens/hospital_recommendation_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/dashboard/presentation/screens/operations_dashboard_screen.dart';

/// Route name constants
class AppRoutes {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String permissions = 'permissions';
  static const String home = 'home';
  static const String accidentAlert = 'accident-alert';
  static const String severityResult = 'severity-result';
  static const String emergencyContacts = 'emergency-contacts';
  static const String liveTracking = 'live-tracking';
  static const String hospitals = 'hospitals';
  static const String dashboard = 'dashboard';
  static const String profile = 'profile';
}

/// Shell widget for bottom navigation
class _MainShell extends StatefulWidget {
  final Widget child;
  final GoRouterState state;

  const _MainShell({required this.child, required this.state});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  @override
  void didUpdateWidget(covariant _MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateIndex();
  }

  @override
  void initState() {
    super.initState();
    _updateIndex();
  }

  void _updateIndex() {
    final location = widget.state.uri.toString();
    if (location.startsWith('/contacts')) {
      _currentIndex = 1;
    } else if (location.startsWith('/dashboard')) {
      _currentIndex = 2;
    } else if (location.startsWith('/profile')) {
      _currentIndex = 3;
    } else {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.dividerTheme.color ?? Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.goNamed(AppRoutes.home);
                break;
              case 1:
                context.goNamed(AppRoutes.emergencyContacts);
                break;
              case 2:
                context.goNamed(AppRoutes.dashboard);
                break;
              case 3:
                context.goNamed(AppRoutes.profile);
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contacts_outlined),
              activeIcon: Icon(Icons.contacts_rounded),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Ops',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/// GoRouter configuration provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // ─── Auth Routes ───
      GoRoute(
        path: '/splash',
        name: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/permissions',
        name: AppRoutes.permissions,
        builder: (context, state) => const PermissionsScreen(),
      ),

      // ─── Main Shell (Bottom Nav) ───
      ShellRoute(
        builder: (context, state, child) =>
            _MainShell(state: state, child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/contacts',
            name: AppRoutes.emergencyContacts,
            builder: (context, state) => const EmergencyContactsScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            name: AppRoutes.dashboard,
            builder: (context, state) => const OperationsDashboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ─── Emergency Flow Routes ───
      GoRoute(
        path: '/accident-alert',
        name: AppRoutes.accidentAlert,
        builder: (context, state) => const AccidentAlertScreen(),
      ),
      GoRoute(
        path: '/severity-result',
        name: AppRoutes.severityResult,
        builder: (context, state) => const SeverityResultScreen(),
      ),
      GoRoute(
        path: '/hospitals',
        name: AppRoutes.hospitals,
        builder: (context, state) => const HospitalRecommendationScreen(),
      ),
      GoRoute(
        path: '/tracking',
        name: AppRoutes.liveTracking,
        builder: (context, state) => const LiveTrackingScreen(),
      ),
    ],
  );
});
