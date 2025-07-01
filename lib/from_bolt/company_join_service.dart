import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyJoinService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<CompanyJoinResult> searchCompany(String username) async {
    try {
      final response = await _supabase
          .from('companies')
          .select('id, company_name, username')
          .eq('username', username)
          .maybeSingle();

      if (response != null) {
        return CompanyJoinResult.success(
          CompanyInfo(
            id: response['id'],
            name: response['company_name'],
            username: response['username'],
          ),
        );
      } else {
        return CompanyJoinResult.error('Company not found');
      }
    } catch (e) {
      return CompanyJoinResult.error('Search failed: $e');
    }
  }

  static Future<CompanyJoinResult> requestJoin(String companyId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return CompanyJoinResult.error('User not logged in');
      }

      // Check if request already exists
      final existingRequest = await _supabase
          .from('join_requests')
          .select('id')
          .eq('user_id', userId)
          .eq('company_id', companyId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingRequest != null) {
        return CompanyJoinResult.error('Request already sent');
      }

      await _supabase.from('join_requests').insert({
        'user_id': userId,
        'company_id': companyId,
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      });

      return CompanyJoinResult.success(null);
    } catch (e) {
      return CompanyJoinResult.error('Request failed: $e');
    }
  }

  static Future<List<JoinRequest>> getJoinRequests(String companyId) async {
    try {
      final response = await _supabase
          .from('join_requests')
          .select('''
            id, user_id, status, requested_at,
            users!join_requests_user_id_fkey(
              id, email, full_name, profile_image
            )
          ''')
          .eq('company_id', companyId)
          .eq('status', 'pending')
          .order('requested_at', ascending: false);

      return response.map<JoinRequest>((item) {
        final userData = item['users'];
        return JoinRequest(
          id: item['id'],
          userId: item['user_id'],
          companyId: companyId,
          status: item['status'],
          requestedAt: DateTime.parse(item['requested_at']),
          userEmail: userData['email'],
          userFullName: userData['full_name'],
          userProfileImage: userData['profile_image'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching join requests: $e');
      return [];
    }
  }

  static Future<bool> approveJoinRequest(String requestId, String userId, String companyId) async {
    try {
      // Update user's company_id
      await _supabase
          .from('users')
          .update({'company_id': companyId})
          .eq('id', userId);

      // Update request status
      await _supabase
          .from('join_requests')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      return true;
    } catch (e) {
      print('Error approving join request: $e');
      return false;
    }
  }

  static Future<bool> rejectJoinRequest(String requestId) async {
    try {
      await _supabase
          .from('join_requests')
          .update({
            'status': 'rejected',
            'rejected_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      return true;
    } catch (e) {
      print('Error rejecting join request: $e');
      return false;
    }
  }
}

class CompanyJoinResult {
  final bool isSuccess;
  final String? error;
  final CompanyInfo? company;

  CompanyJoinResult.success(this.company) : isSuccess = true, error = null;
  CompanyJoinResult.error(this.error) : isSuccess = false, company = null;
}

class CompanyInfo {
  final String id;
  final String name;
  final String username;

  CompanyInfo({
    required this.id,
    required this.name,
    required this.username,
  });
}

class JoinRequest {
  final String id;
  final String userId;
  final String companyId;
  final String status;
  final DateTime requestedAt;
  final String userEmail;
  final String userFullName;
  final String? userProfileImage;

  JoinRequest({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.status,
    required this.requestedAt,
    required this.userEmail,
    required this.userFullName,
    this.userProfileImage,
  });
}