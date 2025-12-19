import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ai_analysis_screen.dart';
import 'screens/report_screen.dart';
import 'screens/map_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/camera_monitor_screen.dart';
import 'widgets/navigation.dart';
import 'widgets/notification_modal.dart';
import 'theme/app_theme.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // If initialization fails we'll continue running the app locally.
  }

  runApp(const TheGuardApp());
}

class TheGuardApp extends StatelessWidget {
  const TheGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return MaterialApp(
      title: 'The Guard',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _isAuthenticated = false;
  String _authMode = 'login'; // 'login' or 'signup'
  String _activeScreen = 'home';
  bool _showNotifications = false;
  final bool _hasUnreadNotifications = true;
  User? _user;

  void _handleLogin(Map<String, String> payload) {
    setState(() {
      final email = payload['email'] ?? 'user@example.com';
      final firstName = payload['firstName'] ?? '';
      final lastName = payload['lastName'] ?? '';
      final name = (firstName.isNotEmpty || lastName.isNotEmpty) ? '$firstName $lastName'.trim() : 'User';

      final childrenJson = payload['children'];
      List<Map<String, String>>? children;
      int childrenCount = 0;
      if (childrenJson != null && childrenJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(childrenJson);
          if (decoded is List) {
            children = decoded.map<Map<String, String>>((e) {
              return {
                'id': e['id']?.toString() ?? '',
                'name': e['name']?.toString() ?? '',
              };
            }).toList();
            childrenCount = children.length;
          }
        } catch (_) {
          // ignore decode errors
        }
      }

      // Fallback: if childrenCount provided or children still null
      final childrenCountStr = payload['childrenCount'] ?? '0';
      final parsedCount = int.tryParse(childrenCountStr) ?? 0;
      if (children == null) {
        childrenCount = parsedCount;
        children = List<Map<String, String>>.generate(childrenCount, (i) => {
              'id': 'child_${i + 1}',
              'name': 'Child ${i + 1}',
            });
      }

      _user = User(
        email: email,
        name: name,
        childrenCount: childrenCount,
        children: children,
      );
      _isAuthenticated = true;
    });
  }

  void _handleSignup(Map<String, String> userData) {
    setState(() {
      final childrenCountStr = userData['childrenCount'] ?? '0';
      final int childrenCount = int.tryParse(childrenCountStr) ?? 0;
      final children = List<Map<String, String>>.generate(childrenCount, (i) => {
            'id': 'child_${i + 1}',
            'name': 'Child ${i + 1}',
          });

      _user = User(
        email: userData['email']!,
        name: "${userData['firstName']} ${userData['lastName']}",
        childrenCount: childrenCount,
        children: children,
      );
      _isAuthenticated = true;
      _activeScreen = 'home';
    });
  }

  void _handleLogout() {
    setState(() {
      _user = null;
      _isAuthenticated = false;
      _activeScreen = 'home';
    });
  }

  Widget _renderScreen() {
    switch (_activeScreen) {
      case 'home':
        return HomeScreen(user: _user);
      case 'ai':
        return const AIAnalysisScreen();
      case 'camera':
        return const CameraMonitorScreen();
      case 'report':
        return const ReportScreen();
      case 'map':
        return const MapScreen();
      case 'chat':
        return const ChatScreen();
      case 'profile':
        return ProfileScreen(onLogout: _handleLogout, user: _user);
      default:
        return HomeScreen(user: _user);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show authentication screens if not logged in
    if (!_isAuthenticated) {
      if (_authMode == 'login') {
        return LoginScreen(
          onLogin: _handleLogin,
          onSwitchToSignup: () => setState(() => _authMode = 'signup'),
        );
      } else {
        return SignupScreen(
          onSignup: _handleSignup,
          onSwitchToLogin: () => setState(() => _authMode = 'login'),
        );
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main App Content
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFf8fafc), // slate-50
                  Color(0x4deff6ff), // blue-50/30
                  Color(0x33eef2ff), // indigo-50/20
                ],
              ),
            ),
            child: Column(
              children: [
                // Professional Status Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 44, 24, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFFe2e8f0).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFdbeafe),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.security,
                              color: Color(0xFF2563eb),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'The Guard',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0f172a),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10b981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Protected',
                                    style: TextStyle(
                                      color: Color(0xFF64748b),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFecfdf5),
                              border: Border.all(
                                color: const Color(0xFFd1fae5),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'All Systems Active',
                              style: TextStyle(
                                color: Color(0xFF047857),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _showNotifications = true),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Stack(
                                children: [
                                  const Icon(
                                    Icons.notifications_outlined,
                                    color: Color(0xFF64748b),
                                    size: 16,
                                  ),
                                  if (_hasUnreadNotifications)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFef4444),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(child: _renderScreen()),

                // Bottom Navigation
                Navigation(
                  activeScreen: _activeScreen,
                  onScreenChange: (screen) => setState(() => _activeScreen = screen),
                ),
              ],
            ),
          ),

          // Notification Modal Overlay
          if (_showNotifications)
            NotificationModal(
              onClose: () => setState(() => _showNotifications = false),
            ),
        ],
      ),
    );
  }
}
