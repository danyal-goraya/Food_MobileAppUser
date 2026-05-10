import '../entities/product.dart';
import '../services/supabase_service.dart';

class ProductModel {
  final SupabaseService _supabaseService;

  ProductModel(this._supabaseService);

  // Get all products
  Future<List<ProductEntity>> getAllProducts() async {
    try {
      return await _supabaseService.getAllProducts();
    } catch (e) {
      print('Get all products error: $e');
      return [];
    }
  }

  // Get products by category
  Future<List<ProductEntity>> getProductsByCategory(String category) async {
    try {
      return await _supabaseService.getProductsByCategory(category);
    } catch (e) {
      print('Get products by category error: $e');
      return [];
    }
  }

  // Get product by ID
  Future<ProductEntity?> getProductById(String productId) async {
    try {
      return await _supabaseService.getProductById(productId);
    } catch (e) {
      print('Get product by ID error: $e');
      return null;
    }
  }

  // Search products by name
  Future<List<ProductEntity>> searchProducts(String query) async {
    try {
      return await _supabaseService.searchProducts(query);
    } catch (e) {
      print('Search products error: $e');
      return [];
    }
  }

  // Get all unique categories
  Future<List<String>> getAllCategories() async {
    try {
      final products = await _supabaseService.getAllProducts();
      final categories = products.map((p) => p.category).toSet().toList();
      categories.sort();
      return categories;
    } catch (e) {
      print('Get categories error: $e');
      return [];
    }
  }

  // Format price for display
  String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  // Calculate discounted price
  double calculateDiscountedPrice(double price, double discountPercentage) {
    return price - (price * discountPercentage / 100);
  }
}
