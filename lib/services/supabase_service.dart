import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user.dart';
import '../entities/product.dart';
import '../entities/cart.dart';
import '../entities/cartitem.dart';
import '../entities/order.dart';
import '../entities/orderitem.dart';
import '../entities/invoice.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  // Get current authenticated user
  User? get currentUser => _client.auth.currentUser;

  // ==================== AUTHENTICATION ====================

  Future<AuthResponse?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // ==================== USER OPERATIONS ====================

  Future<UserEntity?> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _client
          .from('users')
          .insert(userData)
          .select()
          .maybeSingle();

      if (response == null) {
        print('Failed to create user - no response');
        return null;
      }

      return UserEntity.fromJson(response);
    } catch (e) {
      print('Create user error: $e');
      return null;
    }
  }

  Future<UserEntity?> getUserById(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        print('User not found with id: $userId');
        return null;
      }

      return UserEntity.fromJson(response);
    } catch (e) {
      print('Get user by ID error: $e');
      return null;
    }
  }

  Future<UserEntity?> updateUser(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .maybeSingle();

      if (response == null) {
        print('Failed to update user - user not found');
        return null;
      }

      return UserEntity.fromJson(response);
    } catch (e) {
      print('Update user error: $e');
      return null;
    }
  }

  // ==================== PRODUCT OPERATIONS ====================

  Future<ProductEntity?> getProductById(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (response == null) {
        print('Product not found with id: $productId');
        return null;
      }

      return ProductEntity.fromJson(response);
    } catch (e) {
      print('Get product by ID error: $e');
      return null;
    }
  }

  Future<List<ProductEntity>> getAllProducts() async {
    try {
      final response = await _client
          .from('products')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => ProductEntity.fromJson(json))
          .toList();
    } catch (e) {
      print('Get all products error: $e');
      return [];
    }
  }

  Future<List<ProductEntity>> getProductsByCategory(String category) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => ProductEntity.fromJson(json))
          .toList();
    } catch (e) {
      print('Get products by category error: $e');
      return [];
    }
  }

  Future<List<ProductEntity>> searchProducts(String query) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .ilike('name', '%$query%')
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => ProductEntity.fromJson(json))
          .toList();
    } catch (e) {
      print('Search products error: $e');
      return [];
    }
  }

  // ==================== CART OPERATIONS ====================

  Future<CartEntity?> createCart(String userId) async {
    try {
      final response = await _client
          .from('cart')
          .insert({'user_id': userId})
          .select()
          .maybeSingle();

      if (response == null) {
        print('Failed to create cart');
        return null;
      }

      return CartEntity.fromJson(response);
    } catch (e) {
      print('Create cart error: $e');
      return null;
    }
  }

  Future<CartEntity?> getCartByUserId(String userId) async {
    try {
      final response = await _client
          .from('cart')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        print('No cart found for user: $userId');
        return null;
      }

      return CartEntity.fromJson(response);
    } catch (e) {
      print('Get cart by user ID error: $e');
      return null;
    }
  }

  Future<CartItemEntity?> addCartItem({
    required String cartId,
    required String productId,
    required int quantity,
  }) async {
    try {
      final response = await _client
          .from('cart_items')
          .insert({
            'cart_id': cartId,
            'product_id': productId,
            'quantity': quantity,
          })
          .select()
          .maybeSingle();

      if (response == null) {
        print('Failed to add cart item');
        return null;
      }

      return CartItemEntity.fromJson(response);
    } catch (e) {
      print('Add cart item error: $e');
      return null;
    }
  }

  Future<List<CartItemEntity>> getCartItems(String cartId) async {
    try {
      final response = await _client
          .from('cart_items')
          .select()
          .eq('cart_id', cartId);
      return (response as List)
          .map((json) => CartItemEntity.fromJson(json))
          .toList();
    } catch (e) {
      print('Get cart items error: $e');
      return [];
    }
  }

  Future<CartItemEntity?> updateCartItemQuantity(
    String cartItemId,
    int quantity,
  ) async {
    try {
      final response = await _client
          .from('cart_items')
          .update({'quantity': quantity})
          .eq('id', cartItemId)
          .select()
          .maybeSingle();

      if (response == null) {
        print('Cart item not found: $cartItemId');
        return null;
      }

      return CartItemEntity.fromJson(response);
    } catch (e) {
      print('Update cart item quantity error: $e');
      return null;
    }
  }

  Future<bool> removeCartItem(String cartItemId) async {
    try {
      await _client.from('cart_items').delete().eq('id', cartItemId);
      return true;
    } catch (e) {
      print('Remove cart item error: $e');
      return false;
    }
  }

  Future<bool> clearCart(String cartId) async {
    try {
      await _client.from('cart_items').delete().eq('cart_id', cartId);
      return true;
    } catch (e) {
      print('Clear cart error: $e');
      return false;
    }
  }

  // ==================== ORDER OPERATIONS ====================

  Future<OrderEntity?> createOrder({
    required String userId,
    required double totalPrice,
    required String status,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('orders')
          .insert({
            'user_id': userId,
            'total_price': totalPrice,
            'status': status,
            'created_at': now,
          })
          .select()
          .maybeSingle();

      if (response == null) {
        print('Failed to create order');
        return null;
      }

      return OrderEntity.fromJson(response);
    } catch (e) {
      print('Create order error: $e');
      return null;
    }
  }

  Future<OrderEntity?> getOrderById(String orderId) async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .eq('id', orderId)
          .maybeSingle();

      if (response == null) {
        print('Order not found: $orderId');
        return null;
      }

      return OrderEntity.fromJson(response);
    } catch (e) {
      print('Get order by ID error: $e');
      return null;
    }
  }

  Future<List<OrderEntity>> getUserOrders(String userId) async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => OrderEntity.fromJson(json))
          .toList();
    } catch (e) {
      print('Get user orders error: $e');
      return [];
    }
  }

  Future<List<OrderEntity>> getUserOrdersSince(
    String userId,
    DateTime since,
  ) async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => OrderEntity.fromJson(json))
          .toList();
    } catch (e) {
      print('Get user orders since error: $e');
      return [];
    }
  }

  Future<OrderEntity?> updateOrderStatus(String orderId, String status) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updates = <String, dynamic>{'status': status};

      if (status == 'cancelled') {
        updates['cancelled_at'] = now;
      } else if (status == 'delivered') {
        updates['delivered_at'] = now;
      }

      final response = await _client
          .from('orders')
          .update(updates)
          .eq('id', orderId)
          .select()
          .maybeSingle();

      if (response == null) {
        print('Order not found for update: $orderId');
        return null;
      }

      return OrderEntity.fromJson(response);
    } catch (e) {
      print('Update order status error: $e');
      return null;
    }
  }

  // ==================== ORDER ITEM OPERATIONS ====================

  Future<OrderItemEntity?> createOrderItem({
    required String orderId,
    required String productId,
    required int quantity,
    required double priceAtPurchase,
  }) async {
    try {
      final response = await _client
          .from('order_items')
          .insert({
            'order_id': orderId,
            'product_id': productId,
            'quantity': quantity,
            'price_at_purchase': priceAtPurchase,
          })
          .select()
          .maybeSingle();

      if (response == null) {
        print('Failed to create order item');
        return null;
      }

      return OrderItemEntity.fromJson(response);
    } catch (e) {
      print('Create order item error: $e');
      return null;
    }
  }

  Future<List<OrderItemEntity>> getOrderItems(String orderId) async {
    try {
      final response = await _client
          .from('order_items')
          .select()
          .eq('order_id', orderId);
      return (response as List)
          .map((json) => OrderItemEntity.fromJson(json))
          .toList();
    } catch (e) {
      print('Get order items error: $e');
      return [];
    }
  }

  // ==================== INVOICE OPERATIONS ====================

  Future<InvoiceEntity?> createInvoice({
    required String orderId,
    required double totalAmount,
  }) async {
    try {
      final response = await _client
          .from('invoices')
          .insert({'order_id': orderId, 'total_amount': totalAmount})
          .select()
          .maybeSingle();

      if (response == null) {
        print('Failed to create invoice');
        return null;
      }

      return InvoiceEntity.fromJson(response);
    } catch (e) {
      print('Create invoice error: $e');
      return null;
    }
  }

  Future<InvoiceEntity?> getInvoiceByOrderId(String orderId) async {
    try {
      final response = await _client
          .from('invoices')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      if (response == null) {
        print('No invoice found for order: $orderId');
        return null;
      }

      return InvoiceEntity.fromJson(response);
    } catch (e) {
      print('Get invoice by order ID error: $e');
      return null;
    }
  }
}
