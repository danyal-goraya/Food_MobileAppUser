import 'package:flutter/foundation.dart';
import '../entities/product.dart';
import '../models/productdb.dart';

class ProductProvider extends ChangeNotifier {
  final ProductModel _productModel;

  ProductProvider(this._productModel);

  // State
  List<ProductEntity> _products = [];
  List<ProductEntity> _filteredProducts = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategory;
  String _searchQuery = '';

  // Getters
  List<ProductEntity> get products =>
      _filteredProducts.isEmpty &&
          _searchQuery.isEmpty &&
          _selectedCategory == null
      ? _products
      : _filteredProducts;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get hasProducts => _products.isNotEmpty;

  // Load all products
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productModel.getAllProducts();
      _filteredProducts = List.from(_products);
      await _loadCategories();
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load products: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load categories
  Future<void> _loadCategories() async {
    try {
      _categories = await _productModel.getAllCategories();
    } catch (e) {
      print('Failed to load categories: $e');
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      // Reset to all products or filtered by category
      if (_selectedCategory != null) {
        await filterByCategory(_selectedCategory!);
      } else {
        _filteredProducts = List.from(_products);
      }
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _filteredProducts = await _productModel.searchProducts(query);

      // If category is selected, further filter by category
      if (_selectedCategory != null) {
        _filteredProducts = _filteredProducts
            .where((p) => p.category == _selectedCategory)
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Search failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter by category
  Future<void> filterByCategory(String category) async {
    _selectedCategory = category;
    _isLoading = true;
    notifyListeners();

    try {
      final categoryProducts = await _productModel.getProductsByCategory(
        category,
      );

      // If search query exists, further filter by search
      if (_searchQuery.isNotEmpty) {
        _filteredProducts = categoryProducts
            .where(
              (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
      } else {
        _filteredProducts = categoryProducts;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to filter by category: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear category filter
  void clearCategoryFilter() {
    _selectedCategory = null;

    if (_searchQuery.isNotEmpty) {
      searchProducts(_searchQuery);
    } else {
      _filteredProducts = List.from(_products);
      notifyListeners();
    }
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';

    if (_selectedCategory != null) {
      filterByCategory(_selectedCategory!);
    } else {
      _filteredProducts = List.from(_products);
      notifyListeners();
    }
  }

  // Clear all filters
  void clearAllFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _filteredProducts = List.from(_products);
    notifyListeners();
  }

  // Get product by ID
  ProductEntity? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Format price
  String formatPrice(double price) {
    return _productModel.formatPrice(price);
  }

  // Calculate discounted price
  double calculateDiscountedPrice(double price, double discountPercentage) {
    return _productModel.calculateDiscountedPrice(price, discountPercentage);
  }

  // Format discounted price
  String formatDiscountedPrice(double price, double discountPercentage) {
    final discounted = calculateDiscountedPrice(price, discountPercentage);
    return formatPrice(discounted);
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh products
  Future<void> refreshProducts() async {
    await loadProducts();
  }
}
