import 'package:flutter/material.dart';
import 'package:food_delivery_user/screens/home_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../entities/order.dart';

class InvoiceScreen extends StatefulWidget {
  final String orderId;

  const InvoiceScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.loadOrderDetails(widget.orderId);
      orderProvider.loadInvoiceDetails(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderProvider = Provider.of<OrderProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final order = orderProvider.selectedOrder;
    final orderItems = orderProvider.selectedOrderItems;
    final invoiceDetails = orderProvider.selectedInvoiceDetails;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF2B2B2B) : Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : Color(0xFF2B2B2B),
          ),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Text(
          'Invoice',
          style: TextStyle(color: isDark ? Colors.white : Color(0xFF2B2B2B)),
        ),
      ),
      body: orderProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFF55951)))
          : order == null
          ? Center(child: Text('Unable to load invoice'))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, size: 50, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Order Placed Successfully!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Color(0xFF2B2B2B),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),

                  // Invoice Card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'INVOICE',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF55951),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'PAID',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 30),

                        // Invoice Details
                        _buildInfoRow(
                          'Invoice Number',
                          orderProvider.formatInvoiceNumber(order.id),
                          isDark,
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow(
                          'Order ID',
                          '#${order.id.substring(0, 8).toUpperCase()}',
                          isDark,
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow(
                          'Date',
                          orderProvider.formatDate(order.createdAt),
                          isDark,
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow(
                          'Customer',
                          authProvider.currentUser?.name ?? 'Guest',
                          isDark,
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow(
                          'Membership',
                          authProvider.currentUser?.userCategory ?? 'Standard',
                          isDark,
                        ),

                        Divider(height: 30),

                        // Order Items
                        Text(
                          'Order Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Color(0xFF2B2B2B),
                          ),
                        ),
                        SizedBox(height: 15),

                        ...orderItems.map((item) {
                          final orderItem = item['orderItem'];
                          final product = item['product'];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Color(0xFF2B2B2B),
                                        ),
                                      ),
                                      Text(
                                        'Qty: ${orderItem.quantity}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF5E5E5E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${(orderItem.priceAtPurchase * orderItem.quantity).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Color(0xFF2B2B2B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        Divider(height: 30),

                        // Totals
                        if (invoiceDetails != null) ...[
                          _buildTotalRow(
                            'Subtotal',
                            invoiceDetails['subtotal'] ?? 0.0,
                            isDark,
                            false,
                          ),
                          if ((invoiceDetails['discount'] ?? 0.0) > 0) ...[
                            SizedBox(height: 8),
                            _buildTotalRow(
                              'Discount (${authProvider.currentUser?.discountPercentage.toStringAsFixed(0)}%)',
                              -(invoiceDetails['discount'] ?? 0.0),
                              isDark,
                              false,
                              isDiscount: true,
                            ),
                          ],
                          Divider(height: 20),
                        ],
                        _buildTotalRow(
                          'Total Amount',
                          order.totalPrice,
                          isDark,
                          true,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement download functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Download feature coming soon'),
                              ),
                            );
                          },
                          icon: Icon(Icons.download),
                          label: Text('Download'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFFF55951),
                            side: BorderSide(color: Color(0xFFF55951)),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigates to HomeScreen and clears the back-stack
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          icon: Icon(Icons.home),
                          label: Text('Go Home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF55951),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Color(0xFF5E5E5E))),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Color(0xFF2B2B2B),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount,
    bool isDark,
    bool isTotal, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount
                ? Color(0xFF4CAF50)
                : (isDark ? Colors.white : Color(0xFF2B2B2B)),
          ),
        ),
        Text(
          amount < 0
              ? '- \$${amount.abs().toStringAsFixed(2)}'
              : '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 15,
            fontWeight: FontWeight.bold,
            color: isDiscount
                ? Color(0xFF4CAF50)
                : (isTotal
                      ? Color(0xFFF55951)
                      : (isDark ? Colors.white : Color(0xFF2B2B2B))),
          ),
        ),
      ],
    );
  }
}
