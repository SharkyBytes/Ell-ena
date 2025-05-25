import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'appwrite_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final AppwriteService _appwriteService = AppwriteService();

  // Create a team and sign up as admin
  Future<Map<String, dynamic>> signUpAsAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user account
      final user = await _appwriteService.createAccount(
        email: email,
        password: password,
        name: name,
      );

      // Create session
      await _appwriteService.createSession(
        email: email,
        password: password,
      );

      // Create team with this user as admin
      await _appwriteService.createTeam(
        userId: user.$id,
        name: name,
        email: email,
      );

      // Get team details (for displaying the team ID)
      final teams = await _appwriteService.getUserTeams(userId: user.$id);
      if (teams.isEmpty) {
        throw Exception('Failed to create team');
      }

      final teamId = teams.first['teamId'];
      
      return {
        'success': true,
        'userId': user.$id,
        'name': name,
        'email': email,
        'teamId': teamId,
        'isAdmin': true,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in signUpAsAdmin: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Join an existing team
  Future<Map<String, dynamic>> signUpAsTeamMember({
    required String email,
    required String password,
    required String name,
    required String teamId,
  }) async {
    try {
      // Check if team exists
      final teamExists = await _appwriteService.checkTeamExists(teamId);
      if (!teamExists) {
        return {
          'success': false,
          'error': 'Team not found. Please check the team ID and try again.',
        };
      }

      // Create user account
      final user = await _appwriteService.createAccount(
        email: email,
        password: password,
        name: name,
      );

      // Create session
      await _appwriteService.createSession(
        email: email,
        password: password,
      );

      // Join the team
      await _appwriteService.joinTeam(
        teamId: teamId,
        userId: user.$id,
        name: name,
        email: email,
      );

      return {
        'success': true,
        'userId': user.$id,
        'name': name,
        'email': email,
        'teamId': teamId,
        'isAdmin': false,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in signUpAsTeamMember: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Create session
      await _appwriteService.createSession(
        email: email,
        password: password,
      );

      // Get current user
      final user = await _appwriteService.getCurrentUser();
      if (user == null) {
        throw Exception('Failed to get user details');
      }

      // Get user's team information
      final teams = await _appwriteService.getUserTeams(userId: user.$id);
      if (teams.isEmpty) {
        throw Exception('User not associated with any team');
      }

      final teamData = teams.first;
      
      return {
        'success': true,
        'userId': user.$id,
        'name': user.name,
        'email': user.email,
        'teamId': teamData['teamId'],
        'isAdmin': teamData['isAdmin'] ?? false,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in login: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      await _appwriteService.deleteSession();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error in logout: $e');
      }
      return false;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await _appwriteService.getCurrentUser();
    return user != null;
  }
  
  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = await _appwriteService.getCurrentUser();
      if (user == null) return null;
      
      return {
        'id': user.$id,
        'name': user.name,
        'email': user.email,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in getCurrentUser: $e');
      }
      return null;
    }
  }
  
  // Get user's team information
  Future<Map<String, dynamic>?> getUserTeams() async {
    try {
      final user = await _appwriteService.getCurrentUser();
      if (user == null) return null;
      
      final teams = await _appwriteService.getUserTeams(userId: user.$id);
      if (teams.isEmpty) return null;
      
      return teams.first;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getUserTeams: $e');
      }
      return null;
    }
  }
} 