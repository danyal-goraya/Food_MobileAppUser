import '../entities/order.dart';
import '../entities/orderitem.dart';
import '../entities/cartitem.dart';
import '../entities/product.dart';
import '../entities/user.dart';
import '../entities/invoice.dart';
import '../services/supabase_service.dart';

class OrderModel {
  final SupabaseService _supabaseService;

  OrderModel(this._supabaseService);

  // Confirm order (create from cart)
  Future<OrderEntity?> confirmOrder({
    required String userId,
    required String cartId,
    required List<Map<String, dynamic>> cartItemsWithProducts,
    required double discountPercentage,
  }) async {
    try {
      // Check if user is blocked
      final user = await _supabaseService.getUserById(userId);
      if (user == null || user.isBlocked) {
        print('User is blocked and cannot place orders');
        return null;
      }

      // Calculate total with discount
      double subtotal = 0.0;
      for (var item in cartItemsWithProducts) {
        final cartItem = item['cartItem'] as CartItemEntity;
        final product = item['product'] as ProductEntity;
        subtotal += product.price * cartItem.quantity;
      }

      final discount = subtotal * (discountPercentage / 100);
      final totalPrice = subtotal - discount;

      // Create order
      final order = await _supabaseService.createOrder(
        userId: userId,
        totalPrice: totalPrice,
        status: 'confirmed',
      );

      if (order == null) return null;

      // Create order items
      for (var item in cartItemsWithProducts) {
        final cartItem = item['cartItem'] as CartItemEntity;
        final product = item['product'] as ProductEntity;

        await _supabaseService.createOrderItem(
          orderId: order.id,
          productId: product.id,
          quantity: cartItem.quantity,
          priceAtPurchase: product.price,
        );
      }

      // Generate invoice
      await _supabaseService.createInvoice(
        orderId: order.id,
        totalAmount: totalPrice,
      );

      // Clear cart
      await _supabaseService.clearCart(cartId);

      return order;
    } catch (e) {
      print('Confirm order error: $e');
      return null;
    }
  }

  // Cancel order with improved blocking logic
  Future<OrderEntity?> cancelOrder(String orderId, String userId) async {
    try {
      final order = await _supabaseService.getOrderById(orderId);
      if (order == null) return null;

      // Can only cancel if order is 'confirmed'
      if (order.status != 'confirmed') {
        print('Order can only be cancelled when status is confirmed');
        return null;
      }

      // Update order status to cancelled
      final cancelledOrder = await _supabaseService.updateOrderStatus(
        orderId,
        'cancelled',
      );

      if (cancelledOrder == null) return null;

      // Increment user's cancellation count
      final user = await _supabaseService.getUserById(userId);
      if (user != null) {
        final newCancellationCount = user.cancellationCount + 1;

        // Update cancellation count
        await _supabaseService.updateUser(userId, {
          'cancellation_count': newCancellationCount,
        });

        // Check if user should be blocked (more than 3 cancellations)
        final shouldBlock = await _shouldBlockUser(userId);

        if (shouldBlock) {
          await _supabaseService.updateUser(userId, {'is_blocked': true});
          print(
            'User $userId has been blocked for exceeding cancellation limit',
          );
        }
      }

      return cancelledOrder;
    } catch (e) {
      print('Cancel order error: $e');
      return null;
    }
  }

  // Check if user should be blocked based on cancellation rules
  // User is blocked if they have MORE THAN 3 cancellations (i.e., 4 or more)
  Future<bool> _shouldBlockUser(String userId) async {
    try {
      // Get cancellations from the last 7 days
      final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
      final recentOrders = await _supabaseService.getUserOrdersSince(
        userId,
        sevenDaysAgo,
      );

      // Count cancelled orders in the last 7 days
      final cancelledCount = recentOrders
          .where((order) => order.status == 'cancelled')
          .length;

      print(
        'User $userId has $cancelledCount cancellations in the last 7 days',
      );

      // Block if more than 3 cancellations (4 or more)
      return cancelledCount > 3;
    } catch (e) {
      print('Check blocking status error: $e');
      return false;
    }
  }

  // Get user orders
  Future<List<OrderEntity>> getUserOrders(String userId) async {
    try {
      return await _supabaseService.getUserOrders(userId);
    } catch (e) {
      print('Get user orders error: $e');
      return [];
    }
  }

  // Get order by ID
  Future<OrderEntity?> getOrderById(String orderId) async {
    try {
      return await _supabaseService.getOrderById(orderId);
    } catch (e) {
      print('Get order by ID error: $e');
      return null;
    }
  }

  // Get order items with product details
  Future<List<Map<String, dynamic>>> getOrderItemsWithProducts(
    String orderId,
  ) async {
    try {
      final orderItems = await _supabaseService.getOrderItems(orderId);
      final itemsWithProducts = <Map<String, dynamic>>[];

      for (var item in orderItems) {
        final product = await _supabaseService.getProductById(item.productId);
        if (product != null) {
          itemsWithProducts.add({'orderItem': item, 'product': product});
        }
      }

      return itemsWithProducts;
    } catch (e) {
      print('Get order items with products error: $e');
      return [];
    }
  }

  // Get invoice for order
  Future<InvoiceEntity?> getOrderInvoice(String orderId) async {
    try {
      return await _supabaseService.getInvoiceByOrderId(orderId);
    } catch (e) {
      print('Get order invoice error: $e');
      return null;
    }
  }

  // Repeat last delivered order
  Future<OrderEntity?> repeatLastDeliveredOrder(
    String userId,
    String cartId,
  ) async {
    try {
      final orders = await _supabaseService.getUserOrders(userId);
      final deliveredOrders =
          orders.where((order) => order.status == 'delivered').toList()
            ..sort((a, b) => b.deliveredAt!.compareTo(a.deliveredAt!));

      if (deliveredOrders.isEmpty) {
        print('No delivered orders found');
        return null;
      }

      final lastOrder = deliveredOrders.first;
      final orderItems = await _supabaseService.getOrderItems(lastOrder.id);

      // Clear current cart
      await _supabaseService.clearCart(cartId);

      // Add items to cart
      for (var item in orderItems) {
        await _supabaseService.addCartItem(
          cartId: cartId,
          productId: item.productId,
          quantity: item.quantity,
        );
      }

      return lastOrder;
    } catch (e) {
      print('Repeat last order error: $e');
      return null;
    }
  }

  // Check if order can be cancelled
  bool canCancelOrder(OrderEntity order) {
    return order.status == 'confirmed';
  }

  // Get order status display text
  String getOrderStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }
}
