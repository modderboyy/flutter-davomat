import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:math';

class EmployeeService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<EmployeeResult> addEmployeeManual({
    required String companyId,
    required String fullName,
    required String position,
    required String email,
    required String password,
  }) async {
    try {
      // Create auth user
      final authResponse = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );

      if (authResponse.user != null) {
        // Create user record
        await _supabase.from('users').insert({
          'id': authResponse.user!.id,
          'email': email,
          'full_name': fullName,
          'position': position,
          'company_id': companyId,
          'is_super_admin': false,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });

        return EmployeeResult.success('Employee added successfully');
      } else {
        return EmployeeResult.error('Failed to create user account');
      }
    } catch (e) {
      return EmployeeResult.error('Error: $e');
    }
  }

  static Future<EmployeeResult> addEmployeesAuto({
    required String companyId,
    required String position,
    required String password,
    required int count,
  }) async {
    try {
      List<String> createdUsers = [];
      
      for (int i = 1; i <= count; i++) {
        final email = _generateEmail(position, i, companyId);
        final fullName = '$position $i';

        try {
          final authResponse = await _supabase.auth.admin.createUser(
            AdminUserAttributes(
              email: email,
              password: password,
              emailConfirm: true,
            ),
          );

          if (authResponse.user != null) {
            await _supabase.from('users').insert({
              'id': authResponse.user!.id,
              'email': email,
              'full_name': fullName,
              'position': position,
              'company_id': companyId,
              'is_super_admin': false,
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
            });

            createdUsers.add(email);
          }
        } catch (e) {
          print('Error creating user $i: $e');
          continue;
        }
      }

      if (createdUsers.isNotEmpty) {
        return EmployeeResult.success('${createdUsers.length} employees created successfully');
      } else {
        return EmployeeResult.error('No employees were created');
      }
    } catch (e) {
      return EmployeeResult.error('Error: $e');
    }
  }

  static Future<EmployeeResult> addEmployeesFromExcel(
    String companyId,
    PlatformFile file,
  ) async {
    try {
      // This is a simplified version - you would need to add excel parsing
      // For now, we'll assume the file contains CSV data
      final String content = String.fromCharCodes(file.bytes!);
      final List<String> lines = content.split('\n');
      
      List<String> createdUsers = [];
      
      // Skip header row
      for (int i = 1; i < lines.length; i++) {
        final List<String> parts = lines[i].split(',');
        if (parts.length >= 4) {
          final fullName = parts[0].trim();
          final position = parts[1].trim();
          final email = parts[2].trim();
          final password = parts[3].trim();

          if (fullName.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
            try {
              final authResponse = await _supabase.auth.admin.createUser(
                AdminUserAttributes(
                  email: email,
                  password: password,
                  emailConfirm: true,
                ),
              );

              if (authResponse.user != null) {
                await _supabase.from('users').insert({
                  'id': authResponse.user!.id,
                  'email': email,
                  'full_name': fullName,
                  'position': position,
                  'company_id': companyId,
                  'is_super_admin': false,
                  'is_active': true,
                  'created_at': DateTime.now().toIso8601String(),
                });

                createdUsers.add(email);
              }
            } catch (e) {
              print('Error creating user from Excel row $i: $e');
              continue;
            }
          }
        }
      }

      if (createdUsers.isNotEmpty) {
        return EmployeeResult.success('${createdUsers.length} employees imported successfully');
      } else {
        return EmployeeResult.error('No employees were imported');
      }
    } catch (e) {
      return EmployeeResult.error('Error importing Excel: $e');
    }
  }

  static String _generateEmail(String position, int index, String companyId) {
    final cleanPosition = position.toLowerCase().replaceAll(' ', '');
    final companyPrefix = companyId.substring(0, 8);
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return '$cleanPosition$index$companyPrefix$random@modderboy.uz';
  }

  static Future<List<Employee>> getEmployees(String companyId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, email, full_name, position, profile_image, is_active, created_at')
          .eq('company_id', companyId)
          .eq('is_super_admin', false)
          .order('created_at', ascending: false);

      return response.map<Employee>((item) => Employee.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching employees: $e');
      return [];
    }
  }

  static Future<bool> updateEmployee({
    required String employeeId,
    required String fullName,
    required String position,
  }) async {
    try {
      await _supabase
          .from('users')
          .update({
            'full_name': fullName,
            'position': position,
          })
          .eq('id', employeeId);

      return true;
    } catch (e) {
      print('Error updating employee: $e');
      return false;
    }
  }

  static Future<bool> toggleEmployeeStatus(String employeeId, bool isActive) async {
    try {
      await _supabase
          .from('users')
          .update({'is_active': isActive})
          .eq('id', employeeId);

      return true;
    } catch (e) {
      print('Error toggling employee status: $e');
      return false;
    }
  }
}

class EmployeeResult {
  final bool isSuccess;
  final String message;

  EmployeeResult.success(this.message) : isSuccess = true;
  EmployeeResult.error(this.message) : isSuccess = false;
}

class Employee {
  final String id;
  final String email;
  final String fullName;
  final String position;
  final String? profileImage;
  final bool isActive;
  final DateTime createdAt;

  Employee({
    required this.id,
    required this.email,
    required this.fullName,
    required this.position,
    this.profileImage,
    required this.isActive,
    required this.createdAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'] ?? '',
      position: json['position'] ?? '',
      profileImage: json['profile_image'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}