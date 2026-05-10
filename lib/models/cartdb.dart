import '../entities/cart.dart';
import '../entities/cartitem.dart';
import '../entities/product.dart';
import '../services/supabase_service.dart';

class CartModel {
  final SupabaseService _supabaseService;

  CartModel(this._supabaseService);

  // Get user's cart
  Future<CartEntity?> getUserCart(String userId) async {
    try {
      return await _supabaseService.getCartByUserId(userId);
    } catch (e) {
      print('Get user cart error: $e');
      return null;
    }
  }

  // Get cart items with product details
  Future<List<Map<String, dynamic>>> getCartItemsWithProducts(
    String cartId,
  ) async {
    try {
      final cartItems = await _supabaseService.getCartItems(cartId);
      final itemsWithProducts = <Map<String, dynamic>>[];

      for (var item in cartItems) {
        final product = await _supabaseService.getProductById(item.productId);
        if (product != null) {
          itemsWithProducts.add({'cartItem': item, 'product': product});
        }
      }

      return itemsWithProducts;
    } catch (e) {
      print('Get cart items with products error: $e');
      return [];
    }
  }

  // Add item to cart
  Future<CartItemEntity?> addToCart({
    required String userId,
    required String productId,
    int quantity = 1,
  }) async {
    try {
      // Get user's cart
      final cart = await _supabaseService.getCartByUserId(userId);
      if (cart == null) return null;

      // Check if item already exists in cart
      final existingItems = await _supabaseService.getCartItems(cart.id);
      final existingItem = existingItems.firstWhere(
        (item) => item.productId == productId,
        orElse: () =>
            CartItemEntity(id: '', cartId: '', productId: '', quantity: 0),
      );

      if (existingItem.id.isNotEmpty) {
        // Update quantity
        return await _supabaseService.updateCartItemQuantity(
          existingItem.id,
          existingItem.quantity + quantity,
        );
      } else {
        // Add new item
        return await _supabaseService.addCartItem(
          cartId: cart.id,
          productId: productId,
          quantity: quantity,
        );
      }
    } catch (e) {
      print('Add to cart error: $e');
      return null;
    }
  }

  // Update cart item quantity
  Future<CartItemEntity?> updateItemQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      if (quantity <= 0) {
        await _supabaseService.removeCartItem(cartItemId);
        return null;
      }
      return await _supabaseService.updateCartItemQuantity(
        cartItemId,
        quantity,
      );
    } catch (e) {
      print('Update item quantity error: $e');
      return null;
    }
  }

  // Remove item from cart
  Future<bool> removeFromCart(String cartItemId) async {
    try {
      await _supabaseService.removeCartItem(cartItemId);
      return true;
    } catch (e) {
      print('Remove from cart error: $e');
      return false;
    }
  }

  // Clear cart
  Future<bool> clearCart(String cartId) async {
    try {
      await _supabaseService.clearCart(cartId);
      return true;
    } catch (e) {
      print('Clear cart error: $e');
      return false;
    }
  }

  // Calculate cart total (without discount)
  double calculateCartTotal(List<Map<String, dynamic>> itemsWithProducts) {
    double total = 0.0;
    for (var item in itemsWithProducts) {
      final cartItem = item['cartItem'] as CartItemEntity;
      final product = item['product'] as ProductEntity;
      total += product.price * cartItem.quantity;
    }
    return total;
  }

  // Calculate cart total with discount
  double calculateCartTotalWithDiscount(
    List<Map<String, dynamic>> itemsWithProducts,
    double discountPercentage,
  ) {
    final subtotal = calculateCartTotal(itemsWithProducts);
    final discount = subtotal * (discountPercentage / 100);
    return subtotal - discount;
  }

  // Get cart item count
  int getCartItemCount(List<CartItemEntity> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }
}
