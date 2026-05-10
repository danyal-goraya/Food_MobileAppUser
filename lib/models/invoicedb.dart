import '../entities/invoice.dart';
import '../entities/order.dart';
import '../entities/orderitem.dart';
import '../entities/product.dart';
import '../services/supabase_service.dart';

class InvoiceModel {
  final SupabaseService _supabaseService;

  InvoiceModel(this._supabaseService);

  // Get invoice details with order items and calculations
  Future<Map<String, dynamic>?> getInvoiceDetails(String orderId) async {
    try {
      final invoice = await _supabaseService.getInvoiceByOrderId(orderId);
      if (invoice == null) return null;

      final order = await _supabaseService.getOrderById(orderId);
      if (order == null) return null;

      final orderItems = await _supabaseService.getOrderItems(orderId);

      // Calculate subtotal from order items
      double subtotal = 0.0;
      for (var item in orderItems) {
        subtotal += item.priceAtPurchase * item.quantity;
      }

      // Calculate discount
      final total = order.totalPrice;
      final discount = subtotal - total;

      return {
        'invoice': invoice,
        'order': order,
        'orderItems': orderItems,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
      };
    } catch (e) {
      print('Get invoice details error: $e');
      return null;
    }
  }

  // Calculate subtotal from items
  double calculateSubtotal(List<Map<String, dynamic>> items) {
    double subtotal = 0.0;
    for (var item in items) {
      if (item.containsKey('orderItem')) {
        final orderItem = item['orderItem'];
        subtotal += orderItem.priceAtPurchase * orderItem.quantity;
      } else if (item.containsKey('cartItem') && item.containsKey('product')) {
        final cartItem = item['cartItem'];
        final product = item['product'];
        subtotal += product.price * cartItem.quantity;
      }
    }
    return subtotal;
  }

  // Format currency
  String formatCurrency(double amount) {
    return 'Rs.${amount.toStringAsFixed(2)}';
  }

  // Format invoice date
  String formatInvoiceDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Format invoice number
  String formatInvoiceNumber(String invoiceId) {
    return 'INV-${invoiceId.substring(0, 8).toUpperCase()}';
  }

  // Generate invoice PDF (placeholder for future implementation)
  Future<bool> generateInvoicePDF(String orderId) async {
    try {
      // TODO: Implement PDF generation
      print('PDF generation not yet implemented');
      return false;
    } catch (e) {
      print('Generate invoice PDF error: $e');
      return false;
    }
  }
}
