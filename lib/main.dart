import 'package:flutter/material.dart';
import 'package:food_delivery_user/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Services
import 'services/supabase_service.dart';

// Models
import 'models/userdb.dart';
import 'models/productdb.dart';
import 'models/cartdb.dart';
import 'models/orderdb.dart';
import 'models/invoicedb.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/theme_provider.dart';

// Screens
import 'screens/splash_screen.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url:
        'https://ogkdtfigttrqjxaroxef.supabase.co', // Replace with your Supabase URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9na2R0ZmlndHRycWp4YXJveGVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2MjY5NTUsImV4cCI6MjA3OTIwMjk1NX0.RWPENCUrtEsvqNFHzZldup3fyW6stH0R6rLM1NT38Eo', // Replace with your Supabase Anon Key
  );

  // Run the app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get Supabase client instance
    final supabase = Supabase.instance.client;

    // Create SupabaseService
    final supabaseService = SupabaseService(supabase);

    // Create Model instances
    final userModel = UserModel(supabaseService);
    final productModel = ProductModel(supabaseService);
    final cartModel = CartModel(supabaseService);
    final orderModel = OrderModel(supabaseService);
    final invoiceModel = InvoiceModel(supabaseService);

    return MultiProvider(
      providers: [
        // Theme Provider - Must be first for theme management
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // AuthProvider - Authentication and User Management
        ChangeNotifierProvider(create: (_) => AuthProvider(userModel)),

        // ProductProvider - Product Browsing
        ChangeNotifierProvider(create: (_) => ProductProvider(productModel)),

        // CartProvider - Shopping Cart Management
        ChangeNotifierProvider(create: (_) => CartProvider(cartModel)),

        // OrderProvider - Order Management
        ChangeNotifierProvider(
          create: (_) => OrderProvider(orderModel, invoiceModel),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Food Delivery App',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}
