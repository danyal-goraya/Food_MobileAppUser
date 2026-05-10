import 'package:flutter/foundation.dart';
import '../entities/order.dart';
import '../entities/orderitem.dart';
import '../entities/invoice.dart';
import '../models/orderdb.dart';
import '../models/invoicedb.dart';

class OrderProvider extends ChangeNotifier {
  final OrderModel _orderModel;
  final InvoiceModel _invoiceModel;

  OrderProvider(this._orderModel, this._invoiceModel);

  // State
  List<OrderEntity> _orders = [];
  OrderEntity? _selectedOrder;
  List<Map<String, dynamic>> _selectedOrderItems = [];
  InvoiceEntity? _selectedInvoice;
  Map<String, dynamic>? _selectedInvoiceDetails;
  bool _isLoading = false;
  bool _isConfirmingOrder = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  List<OrderEntity> get orders => _orders;
  OrderEntity? get selectedOrder => _selectedOrder;
  List<Map<String, dynamic>> get selectedOrderItems => _selectedOrderItems;
  InvoiceEntity? get selectedInvoice => _selectedInvoice;
  Map<String, dynamic>? get selectedInvoiceDetails => _selectedInvoiceDetails;
  bool get isLoading => _isLoading;
  bool get isConfirmingOrder => _isConfirmingOrder;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasOrders => _orders.isNotEmpty;

  // Get orders by status
  List<OrderEntity> get confirmedOrders =>
      _orders.where((o) => o.status == 'confirmed').toList();
  List<OrderEntity> get deliveredOrders =>
      _orders.where((o) => o.status == 'delivered').toList();
  List<OrderEntity> get cancelledOrders =>
      _orders.where((o) => o.status == 'cancelled').toList();

  // Load user orders
  Future<void> loadOrders(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderModel.getUserOrders(userId);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load orders: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Confirm order (create from cart) - Returns OrderEntity
  Future<OrderEntity?> confirmOrder({
    required String userId,
    required String cartId,
    required List<Map<String, dynamic>> cartItemsWithProducts,
    required double discountPercentage,
  }) async {
    _isConfirmingOrder = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final order = await _orderModel.confirmOrder(
        userId: userId,
        cartId: cartId,
        cartItemsWithProducts: cartItemsWithProducts,
        discountPercentage: discountPercentage,
      );

      if (order != null) {
        _successMessage = 'Order placed successfully!';
        await loadOrders(userId);
        _isConfirmingOrder = false;
        notifyListeners();
        return order;
      } else {
        _errorMessage = 'Failed to place order. You may be blocked.';
        _isConfirmingOrder = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Order confirmation error: ${e.toString()}';
      _isConfirmingOrder = false;
      notifyListeners();
      return null;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final order = await _orderModel.cancelOrder(orderId, userId);

      if (order != null) {
        _successMessage = 'Order cancelled successfully.';
        await loadOrders(userId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to cancel order. Order may not be cancellable.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Cancel order error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load order details
  Future<void> loadOrderDetails(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedOrder = await _orderModel.getOrderById(orderId);
      if (_selectedOrder != null) {
        _selectedOrderItems = await _orderModel.getOrderItemsWithProducts(
          orderId,
        );
        _selectedInvoice = await _orderModel.getOrderInvoice(orderId);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load order details: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load invoice details
  Future<void> loadInvoiceDetails(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedInvoiceDetails = await _invoiceModel.getInvoiceDetails(orderId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load invoice details: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Repeat last delivered order
  Future<bool> repeatLastOrder(String userId, String cartId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final lastOrder = await _orderModel.repeatLastDeliveredOrder(
        userId,
        cartId,
      );

      if (lastOrder != null) {
        _successMessage = 'Items from your last order have been added to cart!';
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'No delivered orders found to repeat.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Repeat order error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check if order can be cancelled
  bool canCancelOrder(OrderEntity order) {
    return _orderModel.canCancelOrder(order);
  }

  // Get order status text
  String getOrderStatusText(String status) {
    return _orderModel.getOrderStatusText(status);
  }

  // Get order status color
  String getOrderStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return 'orange';
      case 'delivered':
        return 'green';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Calculate order subtotal
  double calculateOrderSubtotal(List<Map<String, dynamic>> items) {
    return _invoiceModel.calculateSubtotal(items);
  }

  // Format currency
  String formatCurrency(double amount) {
    return _invoiceModel.formatCurrency(amount);
  }

  // Format date
  String formatDate(DateTime date) {
    return _invoiceModel.formatInvoiceDate(date);
  }

  // Format invoice number
  String formatInvoiceNumber(String invoiceId) {
    return _invoiceModel.formatInvoiceNumber(invoiceId);
  }

  // Get last delivered order
  OrderEntity? getLastDeliveredOrder() {
    try {
      return deliveredOrders.first;
    } catch (e) {
      return null;
    }
  }

  // Check if user has delivered orders
  bool hasDeliveredOrders() {
    return deliveredOrders.isNotEmpty;
  }

  // Clear selected order
  void clearSelectedOrder() {
    _selectedOrder = null;
    _selectedOrderItems = [];
    _selectedInvoice = null;
    _selectedInvoiceDetails = null;
    notifyListeners();
  }

  // Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear success
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  // Refresh orders
  Future<void> refreshOrders(String userId) async {
    await loadOrders(userId);
  }
}
