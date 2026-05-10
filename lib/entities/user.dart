class UserEntity {
  final String id; // This will be UUID from Supabase Auth
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String role;
  final int totalOrders;
  final int cancellationCount;
  final String userCategory;
  final double discountPercentage;
  final bool isBlocked;
  final DateTime createdAt;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    required this.role,
    required this.totalOrders,
    required this.cancellationCount,
    required this.userCategory,
    required this.discountPercentage,
    required this.isBlocked,
    required this.createdAt,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      role: json['role'] as String,
      totalOrders: json['total_orders'] as int? ?? 0,
      cancellationCount: json['cancellation_count'] as int? ?? 0,
      userCategory: json['user_category'] as String? ?? 'Bronze',
      discountPercentage:
          (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      isBlocked: json['is_blocked'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'total_orders': totalOrders,
      'cancellation_count': cancellationCount,
      'user_category': userCategory,
      'discount_percentage': discountPercentage,
      'is_blocked': isBlocked,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? role,
    int? totalOrders,
    int? cancellationCount,
    String? userCategory,
    double? discountPercentage,
    bool? isBlocked,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      totalOrders: totalOrders ?? this.totalOrders,
      cancellationCount: cancellationCount ?? this.cancellationCount,
      userCategory: userCategory ?? this.userCategory,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
