import 'package:flutter/material.dart';

import 'admin_screens.dart';
import 'app_controller.dart';
import 'home_screen.dart';
import 'shared_widgets.dart';
// import 'chatbot_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = AppController();
  await controller.load();

  runApp(
    SkindecideScope(
      controller: controller,
      child: const SkinDecideApp(),
    ),
  );
}

class SkinDecideApp extends StatelessWidget {
  const SkinDecideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkinDecide',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) {
        final controller = AppController.of(context);
        final routeName = settings.name ?? '/';

        switch (routeName) {
          case '/':
            return const HomeScreen();
          case '/login':
            final nextRoute = settings.arguments as String? ?? '/pengaturan';
            return AdminLoginScreen(nextRoute: nextRoute);
          case '/pengaturan':
            return controller.isAdminLoggedIn
                ? const AdminSettingsScreen()
                : const AdminLoginScreen(nextRoute: '/pengaturan');
          case '/custom-background':
            return controller.isAdminLoggedIn
                ? const CustomBackgroundScreen()
                : const AdminLoginScreen(nextRoute: '/custom-background');
          case '/admin/password':
            return controller.isAdminLoggedIn
                ? const ResetPasswordScreen()
                : const AdminLoginScreen(nextRoute: '/admin/password');
          default:
            return const HomeScreen();
        }
      },
    );
  }
}