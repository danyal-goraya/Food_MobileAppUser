import 'package:flutter/foundation.dart';
import '../entities/cart.dart';
import '../entities/cartitem.dart';
import '../entities/product.dart';
import '../models/cartdb.dart';

class CartProvider extends ChangeNotifier {
  final CartModel _cartModel;

  CartProvider(this._cartModel);

  // State
  CartEntity? _cart;
  List<Map<String, dynamic>> _cartItemsWithProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  double _discountPercentage = 0.0;

  // Getters
  CartEntity? get cart => _cart;
  List<Map<String, dynamic>> get cartItems => _cartItemsWithProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _cartItemsWithProducts.isEmpty;
  int get itemCount => _cartModel.getCartItemCount(
    _cartItemsWithProducts
        .map((item) => item['cartItem'] as CartItemEntity)
        .toList(),
  );

  double get subtotal => _cartModel.calculateCartTotal(_cartItemsWithProducts);
  double get discount => subtotal * (_discountPercentage / 100);
  double get total => _cartModel.calculateCartTotalWithDiscount(
    _cartItemsWithProducts,
    _discountPercentage,
  );

  // Initialize cart for user
  Future<void> initializeCart(String userId, double discountPercentage) async {
    _discountPercentage = discountPercentage;
    _isLoading = true;
    notifyListeners();

    try {
      _cart = await _cartModel.getUserCart(userId);
      if (_cart != null) {
        await loadCartItems();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize cart: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load cart items with product details
  Future<void> loadCartItems() async {
    if (_cart == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _cartItemsWithProducts = await _cartModel.getCartItemsWithProducts(
        _cart!.id,
      );
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load cart items: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add item to cart
  Future<bool> addToCart({
    required String userId,
    required String productId,
    int quantity = 1,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _cartModel.addToCart(
        userId: userId,
        productId: productId,
        quantity: quantity,
      );

      if (result != null) {
        await loadCartItems();
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to add item to cart.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Add to cart error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update item quantity
  Future<bool> updateQuantity(String cartItemId, int quantity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (quantity <= 0) {
        return await removeItem(cartItemId);
      }

      final result = await _cartModel.updateItemQuantity(
        cartItemId: cartItemId,
        quantity: quantity,
      );

      await loadCartItems();
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Update quantity error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Increment item quantity
  Future<bool> incrementQuantity(String cartItemId, int currentQuantity) async {
    return await updateQuantity(cartItemId, currentQuantity + 1);
  }

  // Decrement item quantity
  Future<bool> decrementQuantity(String cartItemId, int currentQuantity) async {
    if (currentQuantity <= 1) {
      return await removeItem(cartItemId);
    }
    return await updateQuantity(cartItemId, currentQuantity - 1);
  }

  // Remove item from cart
  Future<bool> removeItem(String cartItemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _cartModel.removeFromCart(cartItemId);

      if (success) {
        await loadCartItems();
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to remove item.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Remove item error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear cart
  Future<bool> clearCart() async {
    if (_cart == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _cartModel.clearCart(_cart!.id);

      if (success) {
        _cartItemsWithProducts = [];
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to clear cart.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Clear cart error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update discount percentage (when user loyalty changes)
  void updateDiscountPercentage(double discountPercentage) {
    _discountPercentage = discountPercentage;
    notifyListeners();
  }

  // Get item quantity for a product
  int getProductQuantityInCart(String productId) {
    try {
      final item = _cartItemsWithProducts.firstWhere((item) {
        final cartItem = item['cartItem'] as CartItemEntity;
        return cartItem.productId == productId;
      });
      final cartItem = item['cartItem'] as CartItemEntity;
      return cartItem.quantity;
    } catch (e) {
      return 0;
    }
  }

  // Check if product is in cart
  bool isProductInCart(String productId) {
    return getProductQuantityInCart(productId) > 0;
  }

  // Get cart item for a product
  CartItemEntity? getCartItemForProduct(String productId) {
    try {
      final item = _cartItemsWithProducts.firstWhere((item) {
        final cartItem = item['cartItem'] as CartItemEntity;
        return cartItem.productId == productId;
      });
      return item['cartItem'] as CartItemEntity;
    } catch (e) {
      return null;
    }
  }

  // Format currency
  String formatCurrency(double amount) {
    return 'Rs.${amount.toStringAsFixed(2)}';
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh cart
  Future<void> refreshCart() async {
    await loadCartItems();
  }

  calculateDiscountedPrice(double price, double d) {}
}
