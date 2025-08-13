import 'package:agri_farm/screens/user/user_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/order_controller.dart'; // Add import for OrderController
import 'controllers/shipping_controller.dart'; // Add import for ShippingController
import 'screens/admin/admin_navigation_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/utils.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MultiProvider to provide multiple controllers
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CategoryController()),
        ChangeNotifierProxyProvider<CategoryController, ProductController>(
          create: (context) => ProductController(
            Provider.of<CategoryController>(context, listen: false),
          ),
          update: (context, categoryController, previousProductController) =>
              previousProductController?.updateCategoryController(categoryController) ??
              ProductController(categoryController),
        ),
        // Add CartController provider
        ChangeNotifierProvider(create: (_) => CartController()),
        // Add OrderController provider
        ChangeNotifierProvider(create: (_) => OrderController()),
        // Add ShippingController provider
        ChangeNotifierProvider(create: (_) => ShippingController()),
      ],
      child: Consumer<AuthController>(
        builder: (context, authController, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.lightGrey,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                centerTitle: true,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            home: _buildHomeScreen(authController),
          );
        },
      ),
    );
  }

  // Build the appropriate home screen based on authentication state
  Widget _buildHomeScreen(AuthController authController) {
    // Show splash screen while checking authentication
    if (authController.isLoading) {
      return const SplashScreen();
    }

    // If user is logged in, show the appropriate dashboard
    if (authController.isLoggedIn) {
      // Check user role to determine which dashboard to show
      if (authController.isAdmin) {
        return const AdminNavigationScreen();
      } else {
        return const UserNavigationScreen();
      }
    }

    // If not logged in, show the login screen
    return const LoginScreen();
  }
}
