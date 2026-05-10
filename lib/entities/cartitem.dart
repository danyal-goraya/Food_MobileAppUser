class CartItemEntity {
  final String id;
  final String cartId;
  final String productId;
  final int quantity;

  CartItemEntity({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
  });

  factory CartItemEntity.fromJson(Map<String, dynamic> json) {
    return CartItemEntity(
      id: json['id'] as String,
      cartId: json['cart_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart_id': cartId,
      'product_id': productId,
      'quantity': quantity,
    };
  }

  CartItemEntity copyWith({
    String? id,
    String? cartId,
    String? productId,
    int? quantity,
  }) {
    return CartItemEntity(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
    );
  }
}
