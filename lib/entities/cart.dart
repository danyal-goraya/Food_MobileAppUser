class CartEntity {
  final String id;
  final String userId;

  CartEntity({required this.id, required this.userId});

  factory CartEntity.fromJson(Map<String, dynamic> json) {
    return CartEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'user_id': userId};
  }

  CartEntity copyWith({String? id, String? userId}) {
    return CartEntity(id: id ?? this.id, userId: userId ?? this.userId);
  }
}
