

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;
  bool _isInitialized = false;
  
  // Cache for team members to avoid repeated network calls
  List<Map<String, dynamic>> _teamMembersCache = [];
  String? _currentTeamId;
  
  // Cache for current user profile
  Map<String, dynamic>? _userProfileCache;
  
  // Stream controllers for real-time updates
  final _tasksStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _ticketsStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _meetingsStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  
  // Getters for streams
  Stream<List<Map<String, dynamic>>> get tasksStream => _tasksStreamController.stream;
  Stream<List<Map<String, dynamic>>> get ticketsStream => _ticketsStreamController.stream;
  Stream<List<Map<String, dynamic>>> get meetingsStream => _meetingsStreamController.stream;
  
  factory SupabaseService() {
    return _instance;
  }
  
  SupabaseService._internal();
  
  bool get isInitialized => _isInitialized;
  
  // Getter for team members cache
  List<Map<String, dynamic>> get teamMembersCache => _teamMembersCache;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Try to load from .env file
      await dotenv.load().catchError((e) {
        debugPrint('Error loading .env file: $e');
        // If .env file is not found, we'll use hardcoded values below
      });
      
      // Get values from .env or use placeholder values for development
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

        if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Missing required Supabase configuration. Please check your .env file.');
      }
      
      await Supabase.initialize(  
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      
      // Load cached user profile
      await _loadCachedUserProfile();
      
      // Load team members after initialization if user is logged in
      await _loadTeamMembersIfLoggedIn();
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      rethrow;
    } 
  }
  
  // Load cached user profile from local storage
  Future<void> _loadCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedProfile = prefs.getString('user_profile');
      
      if (cachedProfile != null) {
        _userProfileCache = json.decode(cachedProfile) as Map<String, dynamic>;
        debugPrint('Loaded user profile from cache');
      }
    } catch (e) {
      debugPrint('Error loading cached user profile: $e');
    }
  }
  
  // Save user profile to local storage
  Future<void> _saveUserProfileToCache(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', json.encode(profile));
      _userProfileCache = profile;
      debugPrint('Saved user profile to cache');
    } catch (e) {
      debugPrint('Error saving user profile to cache: $e');
    }
  }
  
  // Clear cached user profile
  Future<void> _clearCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile');
      _userProfileCache = null;
      debugPrint('Cleared user profile cache');
    } catch (e) {
      debugPrint('Error clearing cached user profile: $e');
    }
  }
  
  // Load team members if user is logged in
  Future<void> _loadTeamMembersIfLoggedIn() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final userProfile = await getCurrentUserProfile();
        if (userProfile != null && userProfile['team_id'] != null) {
          final teamId = userProfile['team_id'];
          await loadTeamMembers(teamId);
        }
      }
    } catch (e) {
      debugPrint('Error loading team members on init: $e');
    }
  }
  
  // Load team members and cache them
  Future<void> loadTeamMembers(String teamIdOrCode) async {
    try {
      if (!_isInitialized) return;
      
      // Skip if we already have this team's members cached
      if (_currentTeamId == teamIdOrCode && _teamMembersCache.isNotEmpty) {
        return;
      }
      
      // Use the getTeamMembers function to get the team members
      final members = await getTeamMembers(teamIdOrCode);
      
      _teamMembersCache = members;
      _currentTeamId = teamIdOrCode;
      
      debugPrint('Team members loaded: ${_teamMembersCache.length}');
    } catch (e) {
      debugPrint('Error loading team members: $e');
    }
  }
  
  // Get user name from cache by ID
  String getUserNameById(String userId) {
    try {
      final member = _teamMembersCache.firstWhere(
        (member) => member['id'] == userId,
        orElse: () => {'full_name': 'Team Member'},
      );
      return member['full_name'];
    } catch (e) {
      return 'Team Member';
    }
  }
  
  // Check if the user ID is the current user
  bool isCurrentUser(String userId) {
    final currentUserId = _client.auth.currentUser?.id;
    return currentUserId != null && currentUserId == userId;
  }
  
  SupabaseClient get client => _client;
  
  // Generate a random 6-character team ID
  String generateTeamId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  // Create a new team with the generated team ID
  Future<Map<String, dynamic>> createTeam({ 
    required String teamName,
    required String adminName,
    required String adminEmail,
    required String password,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      // Step 1: Register the admin user
      final authResponse = await _client.auth.signUp(
        email: adminEmail,
        password: password,
      );
      
      if (authResponse.user == null) {
        throw Exception('Failed to create user');
      }
      
      final userId = authResponse.user!.id;
      
      // Step 2: Generate a unique team ID
      String teamId;
      bool isUnique = false;
      int attempts = 0;
      
      do {
        teamId = generateTeamId();
        attempts++;
        
        try {
          // Use raw SQL query to avoid RLS issues
          final response = await _client.rpc(
            'check_team_code_exists',
            params: {'code': teamId},
          );
          
          isUnique = response == false;
        } catch (e) {
          debugPrint('Error checking team code: $e');
          // If we can't check, assume it's unique after 3 attempts
          if (attempts >= 3) {
            isUnique = true;
          }
        }
      } while (!isUnique && attempts < 10);
      
      // Step 3: Create the team
      final teamInsertResponse = await _client.from('teams').insert({
        'name': teamName,
        'team_code': teamId,
        'created_by': userId,
        'admin_name': adminName,
        'admin_email': adminEmail,
      }).select();
      
      final teamResponse = teamInsertResponse.isNotEmpty ? teamInsertResponse.first : null;
      
      if (teamResponse == null) {
        throw Exception('Failed to create team');
      }
      
      // Step 4: Update user profile
      await _client.from('users').insert({
        'id': userId,
        'full_name': adminName,
        'email': adminEmail,
        'team_id': teamResponse['id'],
        'role': 'admin',
      });
      
      return {
        'success': true,
        'teamId': teamId,
        'teamData': teamResponse,
      };
    } catch (e) {
      debugPrint('Error creating team: $e');
      return {
        'success': false,
        'error': 'Failed to create team. Please try again.',
      };
    }
  }
  
  // Join an existing team
  Future<Map<String, dynamic>> joinTeam({
    required String teamId,
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      // Step 1: Check if the team exists using direct SQL query
      final teamExistsResponse = await _client.rpc(
        'check_team_code_exists',
        params: {'code': teamId},
      );
      
      if (teamExistsResponse != true) {
        return {
          'success': false,
          'error': 'Team not found',
        };
      }
      
      // Get the team ID
      final teamResponse = await _client
          .from('teams')
          .select('id')
          .eq('team_code', teamId)
          .limit(1);
      
      if (teamResponse.isEmpty) {
        return {
          'success': false,
          'error': 'Team not found',
        };
      }
      
      final teamIdUuid = teamResponse[0]['id'];
      
      // Step 2: Register the user
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (authResponse.user == null) {
        throw Exception('Failed to create user');
      }
      
      final userId = authResponse.user!.id;
      
      // Step 3: Add user to the team
      await _client.from('users').insert({
        'id': userId,
        'full_name': fullName,
        'email': email,
        'team_id': teamIdUuid,
        'role': 'member',
      });
      
      return {
        'success': true,
        'teamId': teamId,
      };
    } catch (e) {
      debugPrint('Error joining team: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Check if a team ID exists
  Future<bool> teamExists(String teamId) async {
    try {
      if (!_isInitialized) return false;
      
      // Use the RPC function to avoid RLS issues
      final response = await _client.rpc(
        'check_team_code_exists',
        params: {'code': teamId},
      );
      
      return response == true;
    } catch (e) {
      debugPrint('Error checking team: $e');
      return false;
    }
  }
  
  // Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile({bool forceRefresh = false}) async {
    try {
      if (!_isInitialized) return null;
      
      final user = _client.auth.currentUser;
      if (user == null) return null;
      
      // Return cached profile if available and not forcing refresh
      if (!forceRefresh && _userProfileCache != null) {
        return _userProfileCache;
      }
      
      final response = await _client
          .from('users')
          .select('*, teams(name, team_code)')
          .eq('id', user.id)
          .maybeSingle();
          
      if (response != null) {
        // Save to cache
        await _saveUserProfileToCache(response);
      }
          
      return response;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return _userProfileCache; // Fallback to cache on error
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    try {
      if (!_isInitialized) return false;
      
      final user = _client.auth.currentUser;
      if (user == null) return false;
      
      await _client
          .from('users')
          .update(data)
          .eq('id', user.id);
      
      // Update the cached profile if it exists
      if (_userProfileCache != null) {
        // Create a new map to avoid modifying the original
        final updatedProfile = Map<String, dynamic>.from(_userProfileCache!);
        
        // Update the fields in the cache
        data.forEach((key, value) {
          updatedProfile[key] = value;
        });
        
        // Save the updated profile to cache
        await _saveUserProfileToCache(updatedProfile);
      }
          
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    if (!_isInitialized) return;
    await _client.auth.signOut();
    await _clearCachedUserProfile();
    _teamMembersCache = [];
    _currentTeamId = null;
  }
  
  // Verify OTP for email verification
  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String token,
    required String type,
    Map<String, dynamic> userData = const {},
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      // Verify the OTP token based on the type
      final OtpType otpType;
      if (type == 'reset_password') {
        otpType = OtpType.recovery;
      } else {
        otpType = OtpType.signup;
      }
      
      final response = await _client.auth.verifyOTP(
        token: token,
        type: otpType,
        email: email,
      );
      
      if (response.user == null) {
        return {
          'success': false,
          'error': 'Invalid verification code',
        };
      }
      
      // Wait a moment for the auth to fully process
      await Future.delayed(const Duration(milliseconds: 500));

      // Set the user's password if provided
      String? password = userData['password'] as String?;
      if (password != null && password.isNotEmpty) {
        try {
          // User is already signed in after OTP verification, 
          // so we can update their password
          await _client.auth.updateUser(
            UserAttributes(
              password: password,
            ),
          );
        } catch (e) {
          debugPrint('Error setting password: $e');
          // Continue even if password setting fails
        }
      }
      
      // Handle different verification types
      if (type == 'signup_create' && userData.isNotEmpty) {
        try {
          // Generate a unique team ID
          String teamId;
          bool isUnique = false;
          int attempts = 0;
          
          do {
            teamId = generateTeamId();
            attempts++;
            
            try {
              final checkResponse = await _client.rpc(
                'check_team_code_exists',
                params: {'code': teamId},
              );
              
              isUnique = checkResponse == false;
            } catch (e) {
              debugPrint('Error checking team code: $e');
              if (attempts >= 3) {
                isUnique = true;
              }
            }
          } while (!isUnique && attempts < 10);
          
          // Step 1: Create the team
          final teamInsertResponse = await _client.from('teams').insert({
            'name': userData['teamName'] ?? 'New Team',
            'team_code': teamId,
            'created_by': response.user!.id,
            'admin_name': userData['adminName'] ?? '',
            'admin_email': email,
          }).select();
          
          final teamResponse = teamInsertResponse.isNotEmpty ? teamInsertResponse.first : null;
          
          if (teamResponse == null) {
            throw Exception('Failed to create team');
          }
          
          // Step 2: Create user profile with proper role
          await _client.from('users').insert({
            'id': response.user!.id,
            'full_name': userData['adminName'] ?? '',
            'email': email,
            'team_id': teamResponse['id'],
            'role': 'admin',
          });
          
          return {
            'success': true,
            'teamId': teamId,
          };
        } catch (e) {
          debugPrint('Error creating team after verification: $e');
          return {
            'success': false,
            'error': e.toString(),
          };
        }
      } else if (type == 'signup_join' && userData.isNotEmpty) {
        try {
          // Get the team ID
          final teamResponse = await _client
              .from('teams')
              .select('id')
              .eq('team_code', userData['teamId'])
              .limit(1);
          
          if (teamResponse.isEmpty) {
            return {
              'success': false,
              'error': 'Team not found',
            };
          }
          
          final teamIdUuid = teamResponse[0]['id'];
          
          // Create user profile with proper role
          await _client.from('users').insert({
            'id': response.user!.id,
            'full_name': userData['fullName'] ?? '',
            'email': email,
            'team_id': teamIdUuid,
            'role': 'member',
          });
          
          return {
            'success': true,
          };
        } catch (e) {
          debugPrint('Error joining team after verification: $e');
          return {
            'success': false,
            'error': e.toString(),
          };
        }
      } else if (type == 'reset_password') {
        // For password reset, just return success
        return {
          'success': true,
        };
      }
      
      // Default success response
      return {
        'success': true,
      };
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Resend verification email
  Future<Map<String, dynamic>> resendVerificationEmail(String email, {String type = 'signup'}) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false, 
          'error': 'Supabase is not initialized',
        };
      }
      
      final OtpType otpType;
      if (type == 'reset_password') {
        // For password reset, we need to call resetPasswordForEmail instead of resend
        await _client.auth.resetPasswordForEmail(email);
      } else {
        // For signup and other types, use the resend method
        otpType = type == 'signup' ? OtpType.signup : OtpType.email;
        await _client.auth.resend(
          type: otpType,
          email: email,
        );
      }
      
      return {
        'success': true,
      };
    } catch (e) {
      debugPrint('Error resending verification email: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Get all members of a specific team
  Future<List<Map<String, dynamic>>> getTeamMembers(String teamIdOrCode) async {
    try {
      if (!_isInitialized) return [];
      
      final user = _client.auth.currentUser;
      if (user == null) return [];
      
      String teamIdUuid;
      
      // Check if the input is already a UUID
      final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
      if (uuidPattern.hasMatch(teamIdOrCode)) {
        teamIdUuid = teamIdOrCode;
      } else {
        // First, get the UUID of the team from the team code
        final teamResponse = await _client
            .from('teams')
            .select('id')
            .eq('team_code', teamIdOrCode)
            .limit(1);
        
        if (teamResponse.isEmpty) return [];
        
        teamIdUuid = teamResponse[0]['id'];
      }
      
      // Then get all users in that team
      final response = await _client
          .from('users')
          .select('*')
          .eq('team_id', teamIdUuid)
          .order('role', ascending: false); // Put admins first
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting team members: $e');
      return [];
    }
  }
  
  // Task-related methods
  
  // Get tasks for the current user's team
  Future<List<Map<String, dynamic>>> getTasks({
    bool filterByAssignment = false,
    String? filterByStatus,
    String? filterByDueDate,
  }) async {
    try {
      if (!_isInitialized) return [];
      
      final user = _client.auth.currentUser;
      if (user == null) return [];
      
      // Get the user's team ID
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null || userProfile['team_id'] == null) return [];
      
      final teamId = userProfile['team_id'];
      final userId = user.id;
      final isAdmin = userProfile['role'] == 'admin';
      
      // Create base query
      final query = _client
          .from('tasks')
          .select('*')
          .eq('team_id', teamId);
      
      // Filter by assignment if requested and user is not admin
      if (filterByAssignment && !isAdmin) {
        query.eq('assigned_to', userId);
      } else if (filterByAssignment) {
        // If admin but still wants to see assigned tasks
        query.eq('assigned_to', userId);
      }
      
      // Filter by status if provided
      if (filterByStatus != null) {
        query.eq('status', filterByStatus);
      }
      
      // Filter by due date if provided
      if (filterByDueDate != null) {
        try {
          final date = DateTime.parse(filterByDueDate);
          final startOfDay = DateTime(date.year, date.month, date.day);
          final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
          
          query.gte('due_date', startOfDay.toIso8601String());
          query.lte('due_date', endOfDay.toIso8601String());
        } catch (e) {
          debugPrint('Error parsing due date filter: $e');
        }
      }
      
      final response = await query.order('created_at', ascending: false);
          
      // Process the response to make it compatible with existing code
      final List<Map<String, dynamic>> processedTasks = [];
      for (var task in response) {
        final Map<String, dynamic> processedTask = {...task};
        
        // Add creator info
        if (task['created_by'] != null) {
          final creatorInfo = await _getUserInfo(task['created_by']);
          if (creatorInfo != null) {
            processedTask['creator'] = creatorInfo;
          }
        }
        
        // Add assignee info
        if (task['assigned_to'] != null) {
          final assigneeInfo = await _getUserInfo(task['assigned_to']);
          if (assigneeInfo != null) {
            processedTask['assignee'] = assigneeInfo;
          }
        }
        
        processedTasks.add(processedTask);
      }
          
      return processedTasks;
    } catch (e) {
      debugPrint('Error getting tasks: $e');
      return [];
    }
  }
  
  // Create a new task
  Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String? assignedToUserId,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Get the user's team ID
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null || userProfile['team_id'] == null) {
        return {
          'success': false,
          'error': 'User not associated with a team',
        };
      }
      
      final teamId = userProfile['team_id'];
      
      // Create the task
      final Map<String, dynamic> taskData = {
        'title': title,
        'description': description,
        'status': 'todo',
        'approval_status': 'pending',
        'team_id': teamId,
        'created_by': user.id,
      };
      
      if (assignedToUserId != null && assignedToUserId.isNotEmpty) {
        taskData['assigned_to'] = assignedToUserId;
      }
      
      if (dueDate != null) {
        taskData['due_date'] = dueDate.toIso8601String();
      }
      
      final response = await _client
          .from('tasks')
          .insert(taskData)
          .select();
          
      if (response.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to create task',
        };
      }
      
      return {
        'success': true,
        'task': response[0],
      };
    } catch (e) {
      debugPrint('Error creating task: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Update a task's status
  Future<Map<String, dynamic>> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Update the task status
      await _client
          .from('tasks')
          .update({'status': status})
          .eq('id', taskId);
          
      return {
        'success': true,
      };
    } catch (e) {
      debugPrint('Error updating task status: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Update a task's approval status (admin only)
  Future<Map<String, dynamic>> updateTaskApproval({
    required String taskId,
    required String approvalStatus,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Check if user is admin
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null || userProfile['role'] != 'admin') {
        return {
          'success': false,
          'error': 'Only admins can approve tasks',
        };
      }
      
      // Update the task approval status
      await _client
          .from('tasks')
          .update({'approval_status': approvalStatus})
          .eq('id', taskId);
          
      return {
        'success': true,
      };
    } catch (e) {
      debugPrint('Error updating task approval: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Get task details with comments
  Future<Map<String, dynamic>?> getTaskDetails(String taskId) async {
    try {
      if (!_isInitialized) return null;
      
      final user = _client.auth.currentUser;
      if (user == null) return null;
      
      // Get task details
      final taskResponse = await _client
          .from('tasks')
          .select('*')
          .eq('id', taskId)
          .single();
      
      // Get task comments
      final commentsResponse = await _client
          .from('task_comments')
          .select('*')
          .eq('task_id', taskId)
          .order('created_at', ascending: true);
          
      // Get creator and assignee info
      String? createdById = taskResponse['created_by'];
      String? assignedToId = taskResponse['assigned_to'];
      
      Map<String, dynamic>? creator;
      Map<String, dynamic>? assignee;
      
      if (createdById != null) {
        final creatorResponse = await _client
            .from('users')
            .select('id, full_name')
            .eq('id', createdById)
            .maybeSingle();
        
        if (creatorResponse != null) {
          creator = creatorResponse;
        }
      }
      
      if (assignedToId != null) {
        final assigneeResponse = await _client
            .from('users')
            .select('id, full_name')
            .eq('id', assignedToId)
            .maybeSingle();
        
        if (assigneeResponse != null) {
          assignee = assigneeResponse;
        }
      }
      
      // Get comment user info
      List<Map<String, dynamic>> commentsWithUsers = [];
      for (var comment in commentsResponse) {
        String? userId = comment['user_id'];
        Map<String, dynamic>? user;
        
        if (userId != null) {
          final userResponse = await _client
              .from('users')
              .select('id, full_name')
              .eq('id', userId)
              .maybeSingle();
          
          if (userResponse != null) {
            user = userResponse;
          }
        }
        
        commentsWithUsers.add({
          ...comment,
          'user': user,
        });
      }
      
      Map<String, dynamic> taskWithDetails = {
        ...taskResponse,
        'creator': creator,
        'assignee': assignee,
      };
          
      return {
        'task': taskWithDetails,
        'comments': commentsWithUsers,
      };
    } catch (e) {
      debugPrint('Error getting task details: $e');
      return null;
    }
  }
  
  // Add a comment to a task
  Future<Map<String, dynamic>> addTaskComment({
    required String taskId,
    required String content,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Add the comment
      final response = await _client
          .from('task_comments')
          .insert({
            'task_id': taskId,
            'user_id': user.id,
            'content': content,
          })
          .select();
          
      if (response.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to add comment',
        };
      }
      
      // Get user info
      final userResponse = await _client
          .from('users')
          .select('id, full_name')
          .eq('id', user.id)
          .maybeSingle();
      
      final commentWithUser = {
        ...response[0],
        'user': userResponse,
      };
          
      return {
        'success': true,
        'comment': commentWithUser,
      };
    } catch (e) {
      debugPrint('Error adding task comment: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Ticket-related methods
  
  // Get predefined ticket categories
  List<String> getTicketCategories() {
    return ['Bug', 'Feature Request', 'UI/UX', 'Performance', 'Documentation', 'Security', 'Other'];
  }
  
  // Get tickets for the current user's team
  Future<List<Map<String, dynamic>>> getTickets({
    bool filterByAssignment = false,
    String? filterByStatus,
    String? filterByPriority,
  }) async {
    try {
      if (!_isInitialized) return [];
      
      final user = _client.auth.currentUser;
      if (user == null) return [];
      
      // Get the user's team ID
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null || userProfile['team_id'] == null) return [];
      
      final teamId = userProfile['team_id'];
      final userId = user.id;
      final isAdmin = userProfile['role'] == 'admin';
      
      // Create base query
      final query = _client
          .from('tickets')
          .select('*')
          .eq('team_id', teamId);
      
      // Filter by assignment if requested and user is not admin
      if (filterByAssignment && !isAdmin) {
        query.eq('assigned_to', userId);
      } else if (filterByAssignment) {
        // If admin but still wants to see assigned tickets
        query.eq('assigned_to', userId);
      }
      
      // Filter by status if provided
      if (filterByStatus != null) {
        query.eq('status', filterByStatus);
      }
      
      // Filter by priority if provided
      if (filterByPriority != null) {
        query.eq('priority', filterByPriority);
      }
      
      final response = await query.order('created_at', ascending: false);
          
      // Process the response to add creator and assignee info
      final List<Map<String, dynamic>> processedTickets = [];
      for (var ticket in response) {
        final Map<String, dynamic> processedTicket = {...ticket};
        
        // Add creator info
        if (ticket['created_by'] != null) {
          final creatorInfo = await _getUserInfo(ticket['created_by']);
          if (creatorInfo != null) {
            processedTicket['creator'] = creatorInfo;
          }
        }
        
        // Add assignee info
        if (ticket['assigned_to'] != null) {
          final assigneeInfo = await _getUserInfo(ticket['assigned_to']);
          if (assigneeInfo != null) {
            processedTicket['assignee'] = assigneeInfo;
          }
        }
        
        processedTickets.add(processedTicket);
      }
          
      return processedTickets;
    } catch (e) {
      debugPrint('Error getting tickets: $e');
      return [];
    }
  }
  
  // Helper method to get user info
  Future<Map<String, dynamic>?> _getUserInfo(String userId) async {
    try {
      // First check the cache
      final cachedUser = _teamMembersCache.firstWhere(
        (member) => member['id'] == userId,
        orElse: () => {},
      );
      
      if (cachedUser.isNotEmpty) {
        return {
          'id': cachedUser['id'],
          'full_name': cachedUser['full_name'],
          'role': cachedUser['role'],
        };
      }
      
      // If not in cache, fetch from database
      final response = await _client
          .from('users')
          .select('id, full_name, role')
          .eq('id', userId)
          .limit(1);
          
      if (response.isNotEmpty) {
        return {
          'id': response[0]['id'],
          'full_name': response[0]['full_name'],
          'role': response[0]['role'],
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user info: $e');
      return null;
    }
  }
  
  // Create a new ticket
  Future<Map<String, dynamic>> createTicket({
    required String title,
    String? description,
    required String priority,
    required String category,
    String? assignedToUserId,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Get the user's team ID
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null || userProfile['team_id'] == null) {
        return {
          'success': false,
          'error': 'User not associated with a team',
        };
      }
      
      final teamId = userProfile['team_id'];
      
      // Create the ticket
      final Map<String, dynamic> ticketData = {
        'title': title,
        'description': description,
        'priority': priority,
        'category': category,
        'status': 'open',
        'approval_status': 'pending',
        'team_id': teamId,
        'created_by': user.id,
      };
      
      if (assignedToUserId != null && assignedToUserId.isNotEmpty) {
        ticketData['assigned_to'] = assignedToUserId;
      }
      
      final response = await _client
          .from('tickets')
          .insert(ticketData)
          .select();
          
      if (response.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to create ticket',
        };
      }
      
      // Refresh tickets
      await getTickets();
      
      return {
        'success': true,
        'ticket': response[0],
      };
    } catch (e) {
      debugPrint('Error creating ticket: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Update a ticket's status
  Future<Map<String, dynamic>> updateTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Update the ticket status
      await _client
          .from('tickets')
          .update({'status': status})
          .eq('id', ticketId);
          
      // Refresh tickets
      await getTickets();
      
      return {
        'success': true,
      };
    } catch (e) {
      debugPrint('Error updating ticket status: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Update a ticket's priority
  Future<Map<String, dynamic>> updateTicketPriority({
    required String ticketId,
    required String priority,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Update the ticket priority
      await _client
          .from('tickets')
          .update({'priority': priority})
          .eq('id', ticketId);
          
      // Refresh tickets
      await getTickets();
      
      return {
        'success': true,
      };
    } catch (e) {
      debugPrint('Error updating ticket priority: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Update a ticket's approval status (admin only)
  Future<Map<String, dynamic>> updateTicketApproval({
    required String ticketId,
    required String approvalStatus,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Check if user is admin
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null || userProfile['role'] != 'admin') {
        return {
          'success': false,
          'error': 'Only admins can approve tickets',
        };
      }
      
      // Update the ticket approval status
      await _client
          .from('tickets')
          .update({'approval_status': approvalStatus})
          .eq('id', ticketId);
          
      // Refresh tickets
      await getTickets();
      
      return {
        'success': true,
      };
    } catch (e) {
      debugPrint('Error updating ticket approval: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Get ticket details with comments
  Future<Map<String, dynamic>?> getTicketDetails(String ticketId) async {
    try {
      if (!_isInitialized) return null;
      
      final user = _client.auth.currentUser;
      if (user == null) return null;
      
      // Get ticket details
      final ticketResponse = await _client
          .from('tickets')
          .select('*')
          .eq('id', ticketId)
          .single();
      
      // Get ticket comments
      final commentsResponse = await _client
          .from('ticket_comments')
          .select('*')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);
          
      // Get creator and assignee info
      String? createdById = ticketResponse['created_by'];
      String? assignedToId = ticketResponse['assigned_to'];
      
      Map<String, dynamic>? creator;
      Map<String, dynamic>? assignee;
      
      if (createdById != null) {
        creator = await _getUserInfo(createdById);
      }
      
      if (assignedToId != null) {
        assignee = await _getUserInfo(assignedToId);
      }
      
      // Get comment user info
      List<Map<String, dynamic>> commentsWithUsers = [];
      for (var comment in commentsResponse) {
        String? userId = comment['user_id'];
        Map<String, dynamic>? user;
        
        if (userId != null) {
          user = await _getUserInfo(userId);
        }
        
        commentsWithUsers.add({
          ...comment,
          'user': user,
        });
      }
      
      Map<String, dynamic> ticketWithDetails = {
        ...ticketResponse,
        'creator': creator,
        'assignee': assignee,
      };
          
      return {
        'ticket': ticketWithDetails,
        'comments': commentsWithUsers,
      };
    } catch (e) {
      debugPrint('Error getting ticket details: $e');
      return null;
    }
  }
  
  // Add a comment to a ticket
  Future<Map<String, dynamic>> addTicketComment({
    required String ticketId,
    required String content,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Add the comment
      final response = await _client
          .from('ticket_comments')
          .insert({
            'ticket_id': ticketId,
            'user_id': user.id,
            'content': content,
          })
          .select();
          
      if (response.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to add comment',
        };
      }
      
      // Get user info
      final userInfo = await _getUserInfo(user.id);
      
      final commentWithUser = {
        ...response[0],
        'user': userInfo,
      };
          
      return {
        'success': true,
        'comment': commentWithUser,
      };
    } catch (e) {
      debugPrint('Error adding ticket comment: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Assign a ticket to a user
  Future<Map<String, dynamic>> assignTicket({
    required String ticketId,
    required String userId,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Update the ticket
      await _client
          .from('tickets')
          .update({'assigned_to': userId})
          .eq('id', ticketId);
          
      // Refresh tickets
      await getTickets();
      
      return {
        'success': true,
      };
    } catch (e) {
      debugPrint('Error assigning ticket: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Meetings-related methods
  
  // Get meetings for the current user's team
  Future<List<Map<String, dynamic>>> getMeetings() async {
    try {
      if (!_isInitialized) return [];
      
      final user = _client.auth.currentUser;
      if (user == null) return [];
      
      // Get the user's team ID
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null || userProfile['team_id'] == null) return [];
      
      final teamId = userProfile['team_id'];
      
      debugPrint('Fetching meetings for team ID: $teamId');
      
      // Get all meetings for this team
      final response = await _client
          .from('meetings')
          .select('*')
          .eq('team_id', teamId)
          .order('meeting_date', ascending: true);
      
      debugPrint('Raw meetings response: ${response.length} meetings found');
          
      // Process the response to add creator info
      final List<Map<String, dynamic>> processedMeetings = [];
      for (var meeting in response) {
        final Map<String, dynamic> processedMeeting = {...meeting};
        
        // Add creator info if available
        if (meeting['created_by'] != null) {
          final creatorInfo = await _getUserInfo(meeting['created_by']);
          if (creatorInfo != null) {
            processedMeeting['creator'] = creatorInfo;
          }
        }
        
        processedMeetings.add(processedMeeting);
      }
      
      debugPrint('Processed meetings: ${processedMeetings.length}');
      
      // Update the stream
      _meetingsStreamController.add(processedMeetings);
          
      return processedMeetings;
    } catch (e) {
      debugPrint('Error getting meetings: $e');
      return [];
    }
  }
  
  // Create a new meeting
  Future<Map<String, dynamic>> createMeeting({
    required String title,
    String? description,
    required DateTime meetingDate,
    String? meetingUrl,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Get the user's team ID
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null || userProfile['team_id'] == null) {
        return {
          'success': false,
          'error': 'User not associated with a team',
        };
      }
      
      final teamId = userProfile['team_id'];
      
      // Create the meeting
      final Map<String, dynamic> meetingData = {
        'title': title,
        'description': description,
        'meeting_date': meetingDate.toIso8601String(),
        'meeting_url': meetingUrl,
        'team_id': teamId,
        'created_by': user.id,
      };
      
      final response = await _client
          .from('meetings')
          .insert(meetingData)
          .select();
          
      if (response.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to create meeting',
        };
      }
      
      // Refresh meetings
      await getMeetings();
      
      return {
        'success': true,
        'meeting': response[0],
      };
    } catch (e) {
      debugPrint('Error creating meeting: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Get meeting details
  Future<Map<String, dynamic>?> getMeetingDetails(String meetingId) async {
    try {
      if (!_isInitialized) return null;
      
      final user = _client.auth.currentUser;
      if (user == null) return null;
      
      // Get meeting details
      final meetingResponse = await _client
          .from('meetings')
          .select('*')
          .eq('id', meetingId)
          .single();
      
      // Get creator info
      String? createdById = meetingResponse['created_by'];
      Map<String, dynamic>? creator;
      
      if (createdById != null) {
        creator = await _getUserInfo(createdById);
      }
      
      Map<String, dynamic> meetingWithDetails = {
        ...meetingResponse,
        'creator': creator,
      };
          
      return meetingWithDetails;
    } catch (e) {
      debugPrint('Error getting meeting details: $e');
      return null;
    }
  }
  
  // Update a meeting
  Future<Map<String, dynamic>> updateMeeting({
    required String meetingId,
    required String title,
    String? description,
    required DateTime meetingDate,
    String? meetingUrl,
    String? transcription,
    String? ai_summary,
  }) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Update the meeting
      final Map<String, dynamic> meetingData = {
        'title': title,
        'description': description,
        'meeting_date': meetingDate.toIso8601String(),
        'meeting_url': meetingUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Add optional fields if provided
      if (transcription != null) {
        meetingData['transcription'] = transcription;
      }
      
      if (ai_summary != null) {
        meetingData['ai_summary'] = ai_summary;
      }
      
      await _client
          .from('meetings')
          .update(meetingData)
          .eq('id', meetingId);
          
      // Refresh meetings
      await getMeetings();
      
      return {
        'success': true,
      };
    } catch (e) {
      debugPrint('Error updating meeting: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Delete a meeting
  Future<Map<String, dynamic>> deleteMeeting(String meetingId) async {
    try {
      if (!_isInitialized) {
        return {
          'success': false,
          'error': 'Supabase is not initialized',
        };
      }
      
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }
      
      // Delete the meeting
      await _client
          .from('meetings')
          .delete()
          .eq('id', meetingId);
          
      // Refresh meetings
      await getMeetings();
      
      return {
        'success': true,
      };
    } catch (e) {
      debugPrint('Error deleting meeting: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Clean up resources
  void dispose() {
    _tasksStreamController.close();
    _ticketsStreamController.close();
    _meetingsStreamController.close();
  }
} 

