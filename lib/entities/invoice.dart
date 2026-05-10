class InvoiceEntity {
  final String id;
  final String orderId;
  final double totalAmount;
  final DateTime generatedAt;

  InvoiceEntity({
    required this.id,
    required this.orderId,
    required this.totalAmount,
    required this.generatedAt,
  });

  factory InvoiceEntity.fromJson(Map<String, dynamic> json) {
    return InvoiceEntity(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'total_amount': totalAmount,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  InvoiceEntity copyWith({
    String? id,
    String? orderId,
    double? totalAmount,
    DateTime? generatedAt,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      totalAmount: totalAmount ?? this.totalAmount,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
