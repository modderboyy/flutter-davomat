import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Multiple accounts support
  List<UserAccount> _accounts = [];
  UserAccount? _currentAccount;

  List<UserAccount> get accounts => _accounts;
  UserAccount? get currentAccount => _currentAccount;
  bool get hasMultipleAccounts => _accounts.length > 1;

  Future<void> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('user_accounts');
    if (accountsJson != null) {
      final List<dynamic> accountsList = jsonDecode(accountsJson);
      _accounts = accountsList.map((json) => UserAccount.fromJson(json)).toList();
    }

    final currentAccountJson = prefs.getString('current_account');
    if (currentAccountJson != null) {
      _currentAccount = UserAccount.fromJson(jsonDecode(currentAccountJson));
    }
  }

  Future<void> saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = jsonEncode(_accounts.map((account) => account.toJson()).toList());
    await prefs.setString('user_accounts', accountsJson);

    if (_currentAccount != null) {
      await prefs.setString('current_account', jsonEncode(_currentAccount!.toJson()));
    }
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        await _handleSuccessfulAuth(response.user!);
        return AuthResult.success();
      } else {
        return AuthResult.error('Login failed');
      }
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  Future<AuthResult> signInWithGitHub() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('GitHub sign in failed');
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Google sign in failed');
    }
  }

  Future<AuthResult> signUpWithGitHub() async {
    return await signInWithGitHub(); // Same process for OAuth
  }

  Future<AuthResult> signUpWithGoogle() async {
    return await signInWithGoogle(); // Same process for OAuth
  }

  Future<void> _handleSuccessfulAuth(User user) async {
    // Get user details from database
    final userResponse = await _supabase
        .from('users')
        .select('id, email, full_name, is_super_admin, company_id, profile_image')
        .eq('id', user.id)
        .maybeSingle();

    UserAccount account;
    if (userResponse != null) {
      account = UserAccount(
        id: user.id,
        email: userResponse['email'] ?? user.email ?? '',
        fullName: userResponse['full_name'] ?? '',
        isAdmin: userResponse['is_super_admin'] ?? false,
        companyId: userResponse['company_id'],
        profileImage: userResponse['profile_image'],
      );
    } else {
      // Create new user record
      await _supabase.from('users').insert({
        'id': user.id,
        'email': user.email,
        'full_name': user.email?.split('@')[0] ?? 'User',
        'is_super_admin': false,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      account = UserAccount(
        id: user.id,
        email: user.email ?? '',
        fullName: user.email?.split('@')[0] ?? 'User',
        isAdmin: false,
        companyId: null,
        profileImage: null,
      );
    }

    // Add to accounts list if not already present
    final existingIndex = _accounts.indexWhere((acc) => acc.id == account.id);
    if (existingIndex != -1) {
      _accounts[existingIndex] = account;
    } else {
      _accounts.add(account);
    }

    _currentAccount = account;
    await saveAccounts();
  }

  Future<void> switchAccount(UserAccount account) async {
    try {
      // Sign out current user
      await _supabase.auth.signOut();
      
      // This would require storing refresh tokens for each account
      // For now, we'll just switch the current account reference
      _currentAccount = account;
      await saveAccounts();
    } catch (e) {
      print('Error switching account: $e');
    }
  }

  Future<void> removeAccount(UserAccount account) async {
    _accounts.removeWhere((acc) => acc.id == account.id);
    if (_currentAccount?.id == account.id) {
      _currentAccount = _accounts.isNotEmpty ? _accounts.first : null;
    }
    await saveAccounts();
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentAccount = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_account');
  }

  Future<void> signOutAll() async {
    await _supabase.auth.signOut();
    _accounts.clear();
    _currentAccount = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_accounts');
    await prefs.remove('current_account');
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Password reset failed');
    }
  }

  bool get isLoggedIn => _supabase.auth.currentSession != null;
  User? get currentUser => _supabase.auth.currentUser;
}

class UserAccount {
  final String id;
  final String email;
  final String fullName;
  final bool isAdmin;
  final String? companyId;
  final String? profileImage;

  UserAccount({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isAdmin,
    this.companyId,
    this.profileImage,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      isAdmin: json['is_admin'],
      companyId: json['company_id'],
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'is_admin': isAdmin,
      'company_id': companyId,
      'profile_image': profileImage,
    };
  }
}

class AuthResult {
  final bool isSuccess;
  final String? error;

  AuthResult.success() : isSuccess = true, error = null;
  AuthResult.error(this.error) : isSuccess = false;
}