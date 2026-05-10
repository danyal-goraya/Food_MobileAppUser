import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../entities/cartitem.dart';
import '../../entities/product.dart';
import '../screens/invoice_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  Future<void> _confirmOrder(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (authProvider.currentUser == null || cartProvider.cart == null) return;

    // Get the order before confirming (to capture the order ID)
    final order = await orderProvider.confirmOrder(
      userId: authProvider.currentUser!.id,
      cartId: cartProvider.cart!.id,
      cartItemsWithProducts: cartProvider.cartItems,
      discountPercentage: authProvider.currentUser!.discountPercentage,
    );

    if (!context.mounted) return;

    if (order != null) {
      await cartProvider.refreshCart();

      // Navigate to invoice screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => InvoiceScreen(orderId: order.id)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderProvider.errorMessage ?? 'Order failed. You may be blocked.',
          ),
          backgroundColor: Color(0xFFF44336),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF2B2B2B) : Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Text(
          'My Cart',
          style: TextStyle(color: isDark ? Colors.white : Color(0xFF2B2B2B)),
        ),
        actions: [
          if (!cartProvider.isEmpty)
            TextButton(
              onPressed: () => cartProvider.clearCart(),
              child: Text(
                'Clear All',
                style: TextStyle(color: Color(0xFFF55951)),
              ),
            ),
        ],
      ),
      body: cartProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFF55951)))
          : cartProvider.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Color(0xFF5E5E5E).withOpacity(0.5),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Color(0xFF5E5E5E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add items to get started',
                    style: TextStyle(fontSize: 14, color: Color(0xFF5E5E5E)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: cartProvider.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.cartItems[index];
                      final cartItem = item['cartItem'] as CartItemEntity;
                      final product = item['product'] as ProductEntity;

                      // Calculate discounted price properly
                      final originalPrice = product.price;
                      final discountPercentage =
                          authProvider.currentUser?.discountPercentage ?? 0;
                      final discountedPrice =
                          originalPrice * (1 - discountPercentage / 100);

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(12),
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
                        child: Row(
                          children: [
                            // Product Image
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Color(0xFFF55951).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: product.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        product.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.restaurant,
                                                  size: 40,
                                                  color: Color(0xFFF55951),
                                                ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.restaurant,
                                      size: 40,
                                      color: Color(0xFFF55951),
                                    ),
                            ),

                            SizedBox(width: 12),

                            // Product Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Color(0xFF2B2B2B),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  if (discountPercentage > 0) ...[
                                    Text(
                                      '\$${originalPrice.toStringAsFixed(2)} each',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF5E5E5E),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    Text(
                                      '\$${discountedPrice.toStringAsFixed(2)} each',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      '\$${originalPrice.toStringAsFixed(2)} each',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF5E5E5E),
                                      ),
                                    ),
                                  SizedBox(height: 8),
                                  // Quantity Controls
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF55951).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove, size: 18),
                                          color: Color(0xFFF55951),
                                          onPressed: () =>
                                              cartProvider.decrementQuantity(
                                                cartItem.id,
                                                cartItem.quantity,
                                              ),
                                        ),
                                        Text(
                                          '${cartItem.quantity}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Color(0xFF2B2B2B),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add, size: 18),
                                          color: Color(0xFFF55951),
                                          onPressed: () =>
                                              cartProvider.incrementQuantity(
                                                cartItem.id,
                                                cartItem.quantity,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Price and Delete
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFF44336),
                                  ),
                                  onPressed: () =>
                                      cartProvider.removeItem(cartItem.id),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  '\$${(discountedPrice * cartItem.quantity).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF55951),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Order Summary
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF1E1E1E) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white70
                                  : Color(0xFF5E5E5E),
                            ),
                          ),
                          Text(
                            cartProvider.formatCurrency(cartProvider.subtotal),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Color(0xFF2B2B2B),
                            ),
                          ),
                        ],
                      ),
                      if (cartProvider.discount > 0) ...[
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Discount (${authProvider.currentUser?.discountPercentage.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            Text(
                              '- ${cartProvider.formatCurrency(cartProvider.discount)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ],
                      Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Color(0xFF2B2B2B),
                            ),
                          ),
                          Text(
                            cartProvider.formatCurrency(cartProvider.total),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF55951),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _confirmOrder(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF55951),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Place Order',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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
