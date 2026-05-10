import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../entities/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        orderProvider.loadOrders(authProvider.currentUser!.id);
      }
    });
  }

  Future<void> _cancelOrder(String orderId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF1E1E1E)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Order?'),
        content: Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: Color(0xFFF44336)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await orderProvider.cancelOrder(
        orderId,
        authProvider.currentUser!.id,
      );

      if (success) {
        await authProvider.refreshUserData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order cancelled'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    }
  }

  Future<void> _repeatOrder() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (authProvider.currentUser == null || cartProvider.cart == null) return;

    final success = await orderProvider.repeatLastOrder(
      authProvider.currentUser!.id,
      cartProvider.cart!.id,
    );

    if (!mounted) return;

    if (success) {
      await cartProvider.refreshCart();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Last order added to cart!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Failed to repeat order'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderProvider = Provider.of<OrderProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF2B2B2B) : Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Text(
          'My Orders',
          style: TextStyle(color: isDark ? Colors.white : Color(0xFF2B2B2B)),
        ),
        actions: [
          if (orderProvider.hasDeliveredOrders())
            IconButton(
              icon: Icon(Icons.repeat, color: Color(0xFFF55951)),
              onPressed: _repeatOrder,
              tooltip: 'Repeat Last Order',
            ),
        ],
      ),
      body: orderProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFF55951)))
          : !orderProvider.hasOrders
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 100,
                    color: Color(0xFF5E5E5E).withOpacity(0.5),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Color(0xFF5E5E5E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start ordering delicious food!',
                    style: TextStyle(fontSize: 14, color: Color(0xFF5E5E5E)),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  orderProvider.refreshOrders(authProvider.currentUser!.id),
              color: Color(0xFFF55951),
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: orderProvider.orders.length,
                itemBuilder: (context, index) {
                  final order = orderProvider.orders[index];
                  return _OrderCard(
                    order: order,
                    isDark: isDark,
                    onCancel: () => _cancelOrder(order.id),
                    onTap: () => _viewOrderDetails(order),
                  );
                },
              ),
            ),
    );
  }

  void _viewOrderDetails(OrderEntity order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailsSheet(order: order),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.isDark,
    required this.onCancel,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (order.status) {
      case 'confirmed':
        return Color(0xFFFF9800);
      case 'delivered':
        return Color(0xFF4CAF50);
      case 'cancelled':
        return Color(0xFFF44336);
      default:
        return Color(0xFF5E5E5E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Color(0xFF2B2B2B),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    orderProvider.getOrderStatusText(order.status),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Color(0xFF5E5E5E)),
                SizedBox(width: 8),
                Text(
                  orderProvider.formatDate(order.createdAt),
                  style: TextStyle(fontSize: 14, color: Color(0xFF5E5E5E)),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5E5E5E)),
                ),
                Text(
                  orderProvider.formatCurrency(order.totalPrice),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF55951),
                  ),
                ),
              ],
            ),
            if (orderProvider.canCancelOrder(order)) ...[
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFFF44336),
                    side: BorderSide(color: Color(0xFFF44336)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel Order'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  final OrderEntity order;

  const _OrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFF5E5E5E),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Color(0xFF2B2B2B),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Order ID: ${order.id}',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5E5E5E)),
                ),
                SizedBox(height: 8),
                Text(
                  'Date: ${orderProvider.formatDate(order.createdAt)}',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5E5E5E)),
                ),
                SizedBox(height: 8),
                Text(
                  'Status: ${orderProvider.getOrderStatusText(order.status)}',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5E5E5E)),
                ),
                SizedBox(height: 20),
                Text(
                  'Total: ${orderProvider.formatCurrency(order.totalPrice)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF55951),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
