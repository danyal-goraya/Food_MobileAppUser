import '../entities/user.dart';
import '../services/supabase_service.dart';

class UserModel {
  final SupabaseService _supabaseService;

  UserModel(this._supabaseService);

  // Register new user with Supabase Auth (no email confirmation)
  Future<UserEntity?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Sign up with Supabase Auth
      final authResponse = await _supabaseService.signUp(
        email: email,
        password: password,
      );

      if (authResponse == null || authResponse.user == null) {
        print('Auth signup failed');
        return null;
      }

      final userId = authResponse.user!.id;

      // Create user record in database
      final userData = {
        'id': userId,
        'name': name,
        'email': email,
        'role': 'user',
        'total_orders': 0,
        'cancellation_count': 0,
        'user_category': 'Bronze',
        'discount_percentage': 0.0,
        'is_blocked': false,
      };

      final userEntity = await _supabaseService.createUser(userData);

      if (userEntity == null) {
        print('Failed to create user record in database');
        return null;
      }

      // Create cart for new user
      await _supabaseService.createCart(userId);

      return userEntity;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // Login user with Supabase Auth
  Future<UserEntity?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Supabase Auth
      final authResponse = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (authResponse == null || authResponse.user == null) {
        print('Auth signin failed');
        return null;
      }

      final userId = authResponse.user!.id;

      // Get user data from database
      final userEntity = await _supabaseService.getUserById(userId);

      return userEntity;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Logout user
  Future<void> logout() async {
    await _supabaseService.signOut();
  }

  // Get current user
  Future<UserEntity?> getCurrentUser() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return null;

      final userEntity = await _supabaseService.getUserById(currentUser.id);
      return userEntity;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // Update user profile
  Future<UserEntity?> updateProfile({
    required String userId,
    String? phone,
    String? address,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;

      return await _supabaseService.updateUser(userId, updateData);
    } catch (e) {
      print('Update profile error: $e');
      return null;
    }
  }

  // Check if user is blocked
  bool isUserBlocked(UserEntity user) {
    return user.isBlocked;
  }

  // Calculate loyalty discount
  double getLoyaltyDiscount(UserEntity user) {
    return user.discountPercentage;
  }

  // Get user category
  String getUserCategory(UserEntity user) {
    return user.userCategory;
  }

  // Update loyalty status
  Future<UserEntity?> updateLoyaltyStatus(
    String userId,
    int totalOrders,
  ) async {
    try {
      String category;
      double discount;

      if (totalOrders < 5) {
        category = 'Bronze';
        discount = 0.0;
      } else if (totalOrders < 10) {
        category = 'Silver';
        discount = 5.0;
      } else if (totalOrders < 20) {
        category = 'Gold';
        discount = 10.0;
      } else {
        category = 'Platinum';
        discount = 15.0;
      }

      return await _supabaseService.updateUser(userId, {
        'user_category': category,
        'discount_percentage': discount,
      });
    } catch (e) {
      print('Update loyalty status error: $e');
      return null;
    }
  }
}
